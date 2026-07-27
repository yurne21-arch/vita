import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../domain/alimentacion.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class AlimentacionException implements Exception {
  const AlimentacionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Persistencia de Alimentación: perfiles nutricionales y registro de peso.
/// La biblioteca aprobada vive como contenido curado (biblioteca_seed.dart);
/// el motor la usa en memoria. Los planes se regeneran de forma determinista.
class AlimentacionRepository {
  AlimentacionRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const AlimentacionException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  String _fecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AlimentacionException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AlimentacionException(e.message);
    } catch (_) {
      throw const AlimentacionException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  // ── Perfiles ─────────────────────────────────────────────────

  Future<List<PerfilNutricional>> perfiles() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('nutrition_profiles')
            .select()
            .eq('user_id', userId)
            .order('created_at');
        return (rows as List)
            .map((m) => PerfilNutricional.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> guardarPerfil(PerfilNutricional p) => _guard(() async {
        final userId = _userId();
        await _c.from('nutrition_profiles').upsert({
          'user_id': userId,
          'nombre': p.nombre,
          'sexo': p.sexo,
          'edad': p.edad,
          'estatura_cm': p.estaturaCm,
          'peso_kg': p.pesoKg,
          'objetivo': p.objetivo,
          'actividad': p.actividad,
          'ritmo_kg_semana': p.ritmoKgSemana,
          'mantenimiento_estimado': p.mantenimientoEstimado,
          'deficit_aplicado': p.deficitAplicado,
          'kcal_objetivo': p.kcalObjetivo,
          'prot_objetivo_g': p.protObjetivoG,
          'grasa_min_g': p.grasaMinG,
          'carb_dist_pct': p.carbDistPct,
          'kcal_tolerancia_pct': p.kcalToleranciaPct,
          'formula_usada': p.formulaUsada,
          'motivo': p.motivo,
          'fecha_calculo':
              p.fechaCalculo == null ? null : _fecha(p.fechaCalculo!),
          'provisional': p.provisional,
        }, onConflict: 'user_id, nombre');
      });

  // ── Peso ─────────────────────────────────────────────────────

  Future<List<RegistroPeso>> pesos(String persona) => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('nutrition_weight_log')
            .select()
            .eq('user_id', userId)
            .eq('persona', persona)
            .order('fecha', ascending: false);
        return (rows as List)
            .map((m) => RegistroPeso.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> registrarPeso(String persona, DateTime fecha, double pesoKg) =>
      _guard(() async {
        final userId = _userId();
        await _c.from('nutrition_weight_log').upsert({
          'user_id': userId,
          'persona': persona,
          'fecha': _fecha(fecha),
          'peso_kg': pesoKg,
        }, onConflict: 'user_id, persona, fecha');
      });

  // ── Compras (con trazabilidad a Finanzas) ────────────────────

  Future<List<Compra>> compras() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('nutrition_compras')
            .select()
            .eq('user_id', userId)
            .order('fecha', ascending: false);
        return (rows as List)
            .map((m) => Compra.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<Compra> crearCompra({
    String tipo = 'quincenal',
    String? supermercado,
    required DateTime fecha,
    DateTime? periodoInicio,
    DateTime? periodoFin,
    double? monto,
    double? presupuesto,
  }) =>
      _guard(() async {
        final userId = _userId();
        final row = await _c
            .from('nutrition_compras')
            .insert({
              'user_id': userId,
              'tipo': tipo,
              'supermercado': supermercado,
              'fecha': _fecha(fecha),
              'periodo_inicio':
                  periodoInicio == null ? null : _fecha(periodoInicio),
              'periodo_fin': periodoFin == null ? null : _fecha(periodoFin),
              'monto': monto,
              'presupuesto': presupuesto,
            })
            .select()
            .single();
        return Compra.fromMap(row);
      });

  Future<void> actualizarCompra(Compra c) => _guard(() async {
        final userId = _userId();
        await _c
            .from('nutrition_compras')
            .update({
              'supermercado': c.supermercado,
              'fecha': _fecha(c.fecha),
              'monto': c.monto,
              'presupuesto': c.presupuesto,
              'nota': c.nota,
            })
            .eq('id', c.id)
            .eq('user_id', userId);
      });

  /// Registra la compra en Finanzas como gasto de Alimentación (de aquí en
  /// adelante) y guarda el vínculo `finance_tx_id`. Requiere monto > 0.
  /// Comunicación entre módulos a nivel de datos: escribe la tabla de Finanzas,
  /// sin importar su código (los features no se importan entre sí).
  Future<Compra> registrarEnFinanzas(Compra c) => _guard(() async {
        final userId = _userId();
        final monto = c.monto ?? 0;
        if (monto <= 0) {
          throw const AlimentacionException(
              'Ingresa el monto de la compra antes de registrarla.');
        }
        final tx = await _c
            .from('finance_transactions')
            .insert({
              'user_id': userId,
              'tipo': 'gasto',
              'monto': monto,
              'categoria': 'Alimentación',
              'ambito': 'casa',
              'nota': (c.supermercado == null || c.supermercado!.isEmpty)
                  ? 'Compra de alimentación'
                  : 'Compra · ${c.supermercado}',
              'fecha': _fecha(c.fecha),
            })
            .select('id')
            .single();
        final txId = tx['id'] as String;
        await _c
            .from('nutrition_compras')
            .update({'estado': 'comprada', 'finance_tx_id': txId})
            .eq('id', c.id)
            .eq('user_id', userId);
        return Compra(
          id: c.id,
          tipo: c.tipo,
          supermercado: c.supermercado,
          fecha: c.fecha,
          periodoInicio: c.periodoInicio,
          periodoFin: c.periodoFin,
          monto: c.monto,
          estado: 'comprada',
          financeTxId: txId,
          presupuesto: c.presupuesto,
          nota: c.nota,
        );
      });

  Future<List<CompraItem>> itemsDeCompra(String compraId) => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('nutrition_compra_items')
            .select()
            .eq('user_id', userId)
            .eq('compra_id', compraId)
            .order('created_at');
        return (rows as List)
            .map((m) => CompraItem.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> guardarItemCompra(CompraItem it) => _guard(() async {
        final userId = _userId();
        await _c.from('nutrition_compra_items').upsert({
          'id': it.id,
          'user_id': userId,
          'compra_id': it.compraId,
          'food_id': it.foodId,
          'nombre': it.nombre,
          'categoria': it.categoria,
          'cantidad': it.cantidad,
          'unidad': it.unidad,
          'precio': it.precio,
          'estado': it.estado,
          'ya_tengo': it.yaTengo,
          'sustituto': it.sustituto,
        });
      });

  // ── Estados de comida (comí / no comí / cambiada) ────────────

  Future<List<EstadoComida>> estadosComida(DateTime desde, DateTime hasta) =>
      _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('nutrition_meal_state')
            .select()
            .eq('user_id', userId)
            .gte('fecha', _fecha(desde))
            .lte('fecha', _fecha(hasta));
        return (rows as List)
            .map((m) => EstadoComida.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> guardarEstadoComida({
    required DateTime fecha,
    required String momento,
    String? assemblyId,
    String estado = 'planeado',
  }) =>
      _guard(() async {
        final userId = _userId();
        await _c.from('nutrition_meal_state').upsert({
          'user_id': userId,
          'fecha': _fecha(fecha),
          'momento': momento,
          'assembly_id': assemblyId,
          'estado': estado,
        }, onConflict: 'user_id, fecha, momento');
      });

  // ── Cocina de la semana (meal prep) ──────────────────────────

  /// La sesión de cocción de la semana que empieza en [semanaInicio], o null si
  /// aún no existe registro.
  Future<CocinaSesion?> cocinaSesion(DateTime semanaInicio) => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('nutrition_cocina_sesion')
            .select()
            .eq('user_id', userId)
            .eq('semana_inicio', _fecha(semanaInicio))
            .limit(1);
        final list = rows as List;
        if (list.isEmpty) return null;
        return CocinaSesion.fromMap(list.first as Map<String, dynamic>);
      });

  /// Marca la semana como cocinada en [cocinadaAt] (por defecto, ahora).
  Future<void> marcarCocinada(DateTime semanaInicio, {DateTime? cocinadaAt}) =>
      _guard(() async {
        final userId = _userId();
        await _c.from('nutrition_cocina_sesion').upsert({
          'user_id': userId,
          'semana_inicio': _fecha(semanaInicio),
          'cocinada_at':
              (cocinadaAt ?? DateTime.now()).toUtc().toIso8601String(),
        }, onConflict: 'user_id, semana_inicio');
      });

  /// Deshace la marca de cocción de la semana (vuelve a pendiente).
  Future<void> desmarcarCocinada(DateTime semanaInicio) => _guard(() async {
        final userId = _userId();
        await _c.from('nutrition_cocina_sesion').upsert({
          'user_id': userId,
          'semana_inicio': _fecha(semanaInicio),
          'cocinada_at': null,
        }, onConflict: 'user_id, semana_inicio');
      });
}
