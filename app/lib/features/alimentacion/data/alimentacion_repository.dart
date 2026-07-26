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
}
