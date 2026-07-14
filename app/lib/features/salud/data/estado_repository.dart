import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class EstadoException implements Exception {
  const EstadoException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Estado mostrado en la tarjeta "Cómo estás hoy".
/// - peso: el ÚLTIMO registrado (no necesariamente de hoy) + tendencia.
/// - energía / ánimo / sueño: lo de HOY si existe.
class EstadoHoy {
  const EstadoHoy({
    this.pesoUltimo,
    this.pesoTendencia,
    this.pesoEstaSemana = false,
    this.energia,
    this.animo,
    this.suenoCalidad,
    this.suenoHoras,
  });

  final double? pesoUltimo; // kg, cualquier fecha
  final double? pesoTendencia; // kg vs el peso anterior (null si no hay 2)
  final bool pesoEstaSemana; // ya registró peso esta semana
  final int? energia; // hoy 1-5
  final int? animo; // hoy 1-5
  final int? suenoCalidad; // hoy 1=mal, 2=regular, 3=bien
  final double? suenoHoras; // hoy, opcional
}

/// Eventos de Estado General (append-only, eventos separados por métrica).
///
/// Append-only significa que el historial nunca se reescribe. Por eso cada
/// registro solo se inserta si el valor **cambió** respecto al de hoy: volver a
/// abrir la tarjeta y guardar sin tocar nada no debe ensuciar la serie.
class EstadoRepository {
  EstadoRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const EstadoException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  String _fecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String get _hoy => _fecha(DateTime.now());

  String get _inicioSemana {
    final n = DateTime.now();
    final lunes = n.subtract(Duration(days: n.weekday - 1));
    return _fecha(DateTime(lunes.year, lunes.month, lunes.day));
  }

  /// Traduce cualquier fallo de Supabase a un mensaje humano.
  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on EstadoException {
      rethrow;
    } on PostgrestException catch (e) {
      throw EstadoException(e.message);
    } catch (_) {
      throw const EstadoException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  Future<num?> _ultimoHoy(String tabla, String userId, String col) async {
    final rows = await _c
        .from(tabla)
        .select(col)
        .eq('user_id', userId)
        .eq('fecha', _hoy)
        .order('created_at', ascending: false)
        .limit(1);
    final l = rows as List;
    if (l.isEmpty) return null;
    return l.first[col] as num?;
  }

  Future<EstadoHoy> estadoDeHoy() => _guard(() async {
        final userId = _userId();

        // Las 5 lecturas son independientes: van en paralelo.
        final resultados = await Future.wait<dynamic>([
          // Peso: los 2 últimos (cualquier fecha) para valor actual + tendencia.
          _c
              .from('weight_events')
              .select('valor')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(2),
          // ¿Ya registró peso esta semana? (lunes a hoy)
          _c
              .from('weight_events')
              .select('id')
              .eq('user_id', userId)
              .gte('fecha', _inicioSemana)
              .limit(1),
          _ultimoHoy('energy_events', userId, 'valor'),
          _ultimoHoy('mood_events', userId, 'valor'),
          // Sueño de hoy: calidad + horas (ambas pueden venir o no).
          _c
              .from('sleep_events')
              .select('calidad, valor')
              .eq('user_id', userId)
              .eq('fecha', _hoy)
              .order('created_at', ascending: false)
              .limit(1),
        ]);

        final pl = resultados[0] as List;
        double? pesoUltimo;
        double? pesoTend;
        if (pl.isNotEmpty) {
          pesoUltimo = (pl[0]['valor'] as num).toDouble();
          if (pl.length >= 2) {
            pesoTend = pesoUltimo - (pl[1]['valor'] as num).toDouble();
          }
        }

        final pesoEstaSemana = (resultados[1] as List).isNotEmpty;
        final energia = resultados[2] as num?;
        final animo = resultados[3] as num?;

        final sl = resultados[4] as List;
        int? suenoCalidad;
        double? suenoHoras;
        if (sl.isNotEmpty) {
          suenoCalidad = (sl[0]['calidad'] as num?)?.toInt();
          suenoHoras = (sl[0]['valor'] as num?)?.toDouble();
        }

        return EstadoHoy(
          pesoUltimo: pesoUltimo,
          pesoTendencia: pesoTend,
          pesoEstaSemana: pesoEstaSemana,
          energia: energia?.toInt(),
          animo: animo?.toInt(),
          suenoCalidad: suenoCalidad,
          suenoHoras: suenoHoras,
        );
      });

  /// Registro rápido diario: energía, ánimo y/o sueño (calidad + horas).
  ///
  /// Solo escribe las métricas que **cambiaron** respecto a lo ya registrado
  /// hoy. Guardar dos veces sin tocar nada no genera filas nuevas.
  Future<void> registrarDiario({
    int? energia,
    int? animo,
    int? suenoCalidad,
    double? suenoHoras,
  }) =>
      _guard(() async {
        final userId = _userId();

        if (energia != null && (energia < 1 || energia > 5)) {
          throw const EstadoException('La energía va del 1 al 5.');
        }
        if (animo != null && (animo < 1 || animo > 5)) {
          throw const EstadoException('El ánimo va del 1 al 5.');
        }
        if (suenoCalidad != null && (suenoCalidad < 1 || suenoCalidad > 3)) {
          throw const EstadoException('La calidad de sueño va del 1 al 3.');
        }
        if (suenoHoras != null && (suenoHoras < 0 || suenoHoras > 24)) {
          throw const EstadoException('Las horas de sueño van de 0 a 24.');
        }

        final actual = await estadoDeHoy();

        if (energia != null && energia != actual.energia) {
          await _c
              .from('energy_events')
              .insert({'user_id': userId, 'fecha': _hoy, 'valor': energia});
        }
        if (animo != null && animo != actual.animo) {
          await _c
              .from('mood_events')
              .insert({'user_id': userId, 'fecha': _hoy, 'valor': animo});
        }

        // El sueño es una sola fila con dos columnas: se reinserta solo si
        // alguna de las dos cambió, conservando el valor que no se tocó.
        final calidadCambia =
            suenoCalidad != null && suenoCalidad != actual.suenoCalidad;
        final horasCambian =
            suenoHoras != null && suenoHoras != actual.suenoHoras;
        if (calidadCambia || horasCambian) {
          final row = <String, dynamic>{'user_id': userId, 'fecha': _hoy};
          final calidad = suenoCalidad ?? actual.suenoCalidad;
          final horas = suenoHoras ?? actual.suenoHoras;
          if (calidad != null) row['calidad'] = calidad;
          if (horas != null) row['valor'] = horas;
          await _c.from('sleep_events').insert(row);
        }
      });

  /// Registro de peso (semanal o manual).
  Future<void> registrarPeso(double peso) => _guard(() async {
        final userId = _userId();
        if (peso <= 0 || peso >= 500) {
          throw const EstadoException('Ese peso no parece correcto.');
        }
        await _c
            .from('weight_events')
            .insert({'user_id': userId, 'fecha': _hoy, 'valor': peso});
      });
}

final estadoRepositoryProvider = Provider<EstadoRepository>(
  (ref) => EstadoRepository(ref.read(supabaseServiceProvider)),
);
