import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class HabitosException implements Exception {
  const HabitosException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Un hábito con su estado de HOY (hecho / no hecho).
class Habito {
  const Habito({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.hecho,
    this.emoji,
    this.hora,
    this.racha = 0,
    this.cumplidos30 = 0,
  });

  final String id;
  final String nombre;
  final int orden;
  final bool hecho;
  final String? emoji;
  final String? hora;

  /// Días seguidos cumplidos (hasta hoy, o hasta ayer si hoy aún no lo marcas).
  final int racha;

  /// Cuántos de los últimos 30 días se cumplió (para el % de constancia).
  final int cumplidos30;

  Habito copyWith({bool? hecho}) => Habito(
        id: id,
        nombre: nombre,
        orden: orden,
        hecho: hecho ?? this.hecho,
        emoji: emoji,
        hora: hora,
        racha: racha,
        cumplidos30: cumplidos30,
      );
}

/// Estado de un hábito en un día concreto, para el control semanal/mensual.
enum DiaEstado {
  /// Marcó que sí lo hizo.
  hecho,

  /// Marcó que no lo hizo.
  noHecho,

  /// Ese día no le tocaba (p. ej. ejercicio un domingo).
  noTocaba,

  /// Le tocaba pero no quedó registrado (ni sí ni no).
  sinDato,
}

/// Resumen de constancia de un hábito: su semana y su mes.
class SeguimientoHabito {
  const SeguimientoHabito({
    required this.nombre,
    required this.emoji,
    required this.semana,
    required this.mesCumplidos,
    required this.mesProgramados,
  });

  final String nombre;
  final String? emoji;

  /// Últimos 7 días, del más antiguo (índice 0) a hoy (índice 6).
  final List<DiaEstado> semana;

  /// De los últimos 30 días, cuántos le tocaban y cuántos cumplió.
  final int mesCumplidos;
  final int mesProgramados;

  /// Porcentaje de constancia del mes (0 si no le tocó ningún día).
  int get mesPorcentaje =>
      mesProgramados == 0 ? 0 : ((mesCumplidos * 100) / mesProgramados).round();
}

class HabitosRepository {
  HabitosRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  static const _iniciales = [
    {'nombre': 'Leer mis metas', 'emoji': '🎯', 'hora': 'Mañana', 'orden': 1},
    {
      'nombre': 'Citrato de magnesio',
      'emoji': '💊',
      'hora': '6:00 PM',
      'orden': 2
    },
    {'nombre': 'Leer 10–15 min', 'emoji': '📖', 'hora': '9:00 PM', 'orden': 3},
    {
      'nombre': 'Teléfono apagado',
      'emoji': '📵',
      'hora': '9:00 PM',
      'orden': 4
    },
  ];

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const HabitosException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  String _fecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String get _hoy => _fecha(DateTime.now());

  /// Traduce cualquier fallo de Supabase a un mensaje humano.
  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on HabitosException {
      rethrow;
    } on PostgrestException catch (e) {
      throw HabitosException(e.message);
    } catch (_) {
      throw const HabitosException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  /// Crea los 4 hábitos SOLO si el usuario aún no tiene ninguno activo.
  ///
  /// Usa `upsert`: si un hábito con el mismo nombre existe pero desactivado, el
  /// insert violaría `UNIQUE(user_id, nombre)` y dejaría la tarjeta en error.
  Future<void> sembrarSiVacio() => _guard(() async {
        final userId = _userId();

        final existentes = await _c
            .from('habitos')
            .select('id')
            .eq('user_id', userId)
            .eq('activo', true)
            .limit(1);

        if ((existentes as List).isNotEmpty) return;

        final filas = _iniciales
            .map((h) => {
                  'user_id': userId,
                  'nombre': h['nombre'],
                  'emoji': h['emoji'],
                  'hora': h['hora'],
                  'orden': h['orden'],
                  'activo': true,
                })
            .toList();

        await _c.from('habitos').upsert(filas, onConflict: 'user_id,nombre');
      });

  /// Lee los hábitos del usuario con su estado de HOY, su racha (días seguidos)
  /// y su constancia de los últimos 30 días.
  Future<List<Habito>> habitosDeHoy() => _guard(() async {
        final userId = _userId();
        final hoy = DateTime.now();
        // 90 días de historial para calcular rachas largas.
        final desde = _fecha(hoy.subtract(const Duration(days: 90)));

        final resultados = await Future.wait([
          _c
              .from('habitos')
              .select('id, nombre, emoji, hora, orden')
              .eq('user_id', userId)
              .eq('activo', true)
              .order('orden'),
          _c
              .from('habitos_log')
              .select('habito_id, fecha, hecho')
              .eq('user_id', userId)
              .gte('fecha', desde),
        ]);

        // Fechas cumplidas por hábito (solo las hechas) + estado de hoy.
        final cumplidas = <String, Set<String>>{};
        final hechoHoy = <String, bool>{};
        final hoyStr = _fecha(hoy);
        for (final l in (resultados[1] as List)) {
          final hid = l['habito_id'] as String;
          final f = l['fecha'] as String;
          final done = l['hecho'] as bool;
          if (done) (cumplidas[hid] ??= <String>{}).add(f);
          if (f == hoyStr) hechoHoy[hid] = done;
        }

        // Racha: días seguidos cumplidos, contando desde hoy (o ayer si hoy
        // aún no lo marcas, para no romper la racha a media mañana).
        int racha(String hid) {
          final set = cumplidas[hid] ?? const <String>{};
          var cursor = hoy;
          if (!set.contains(hoyStr)) {
            cursor = cursor.subtract(const Duration(days: 1));
          }
          var n = 0;
          while (set.contains(_fecha(cursor))) {
            n++;
            cursor = cursor.subtract(const Duration(days: 1));
          }
          return n;
        }

        // Constancia: cuántos de los últimos 30 días se cumplió.
        int cumplidos30(String hid) {
          final set = cumplidas[hid] ?? const <String>{};
          var n = 0;
          for (var i = 0; i < 30; i++) {
            if (set.contains(_fecha(hoy.subtract(Duration(days: i))))) n++;
          }
          return n;
        }

        return (resultados[0] as List)
            .map((h) => Habito(
                  id: h['id'] as String,
                  nombre: h['nombre'] as String,
                  orden: (h['orden'] as num).toInt(),
                  emoji: h['emoji'] as String?,
                  hora: h['hora'] as String?,
                  hecho: hechoHoy[h['id']] ?? false,
                  racha: racha(h['id'] as String),
                  cumplidos30: cumplidos30(h['id'] as String),
                ))
            .toList();
      });

  /// Alterna hecho/no-hecho para HOY sin duplicar (1 fila por hábito/fecha).
  Future<void> alternar(String habitoId, bool estadoActual) => _guard(() async {
        final userId = _userId();
        await _c.from('habitos_log').upsert(
          {
            'user_id': userId,
            'habito_id': habitoId,
            'fecha': _hoy,
            'hecho': !estadoActual,
          },
          onConflict: 'habito_id,fecha',
        );
      });

  /// Crea un hábito. `upsert` por si existe uno desactivado con el mismo nombre
  /// (evita chocar con UNIQUE(user_id, nombre)); lo reactiva.
  Future<void> crear({required String nombre, String? emoji, String? hora}) =>
      _guard(() async {
        final userId = _userId();
        final limpio = nombre.trim();
        if (limpio.isEmpty) {
          throw const HabitosException('Ponle un nombre al hábito.');
        }
        await _c.from('habitos').upsert({
          'user_id': userId,
          'nombre': limpio,
          'emoji':
              (emoji == null || emoji.trim().isEmpty) ? null : emoji.trim(),
          'hora': (hora == null || hora.trim().isEmpty) ? null : hora.trim(),
          'activo': true,
        }, onConflict: 'user_id,nombre');
      });

  Future<void> editar(String id,
          {required String nombre, String? emoji, String? hora}) =>
      _guard(() async {
        final limpio = nombre.trim();
        if (limpio.isEmpty) {
          throw const HabitosException('Ponle un nombre al hábito.');
        }
        await _c.from('habitos').update({
          'nombre': limpio,
          'emoji':
              (emoji == null || emoji.trim().isEmpty) ? null : emoji.trim(),
          'hora': (hora == null || hora.trim().isEmpty) ? null : hora.trim(),
        }).eq('id', id);
      });

  /// Quita un hábito sin borrar su historial: lo desactiva.
  Future<void> eliminar(String id) => _guard(() async {
        await _c.from('habitos').update({'activo': false}).eq('id', id);
      });

  /// Control de constancia: por cada hábito, su semana (7 días) y su mes (30),
  /// distinguiendo "no lo hice" de "no me tocaba" para que el número sea justo.
  Future<List<SeguimientoHabito>> seguimiento() => _guard(() async {
        final userId = _userId();
        final ahora = DateTime.now();
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);
        final desde = _fecha(hoy.subtract(const Duration(days: 29)));

        final res = await Future.wait([
          _c
              .from('habitos')
              .select('id, nombre, emoji, orden')
              .eq('user_id', userId)
              .eq('activo', true)
              .order('orden'),
          _c
              .from('habito_recordatorios')
              .select('habito_id, dias')
              .eq('user_id', userId)
              .eq('activo', true),
          _c
              .from('habitos_log')
              .select('habito_id, fecha, hecho')
              .eq('user_id', userId)
              .gte('fecha', desde),
        ]);

        // Días en que cada hábito tiene recordatorio (vacío = todos los días).
        final reglas = <String, List<Set<int>>>{};
        for (final r in (res[1] as List)) {
          final hid = r['habito_id'] as String;
          final dias = <int>{
            for (final d in (r['dias'] as List? ?? const []))
              (d as num).toInt(),
          };
          (reglas[hid] ??= <Set<int>>[]).add(dias);
        }
        bool tocaba(String hid, DateTime d) {
          final rs = reglas[hid];
          if (rs == null || rs.isEmpty) return true; // sin reglas = diario
          final wd = d.weekday; // 1=Lun .. 7=Dom
          return rs.any((s) => s.isEmpty || s.contains(wd));
        }

        // Registro por hábito y fecha (sí / no).
        final log = <String, Map<String, bool>>{};
        for (final l in (res[2] as List)) {
          final hid = l['habito_id'] as String;
          (log[hid] ??= <String, bool>{})[l['fecha'] as String] =
              l['hecho'] as bool;
        }

        DiaEstado estado(String hid, DateTime d) {
          if (!tocaba(hid, d)) return DiaEstado.noTocaba;
          final v = log[hid]?[_fecha(d)];
          if (v == null) return DiaEstado.sinDato;
          return v ? DiaEstado.hecho : DiaEstado.noHecho;
        }

        final salida = <SeguimientoHabito>[];
        for (final h in (res[0] as List)) {
          final hid = h['id'] as String;
          final semana = <DiaEstado>[
            for (var i = 6; i >= 0; i--)
              estado(hid, hoy.subtract(Duration(days: i))),
          ];
          var prog = 0, cumpl = 0;
          for (var i = 0; i < 30; i++) {
            final d = hoy.subtract(Duration(days: i));
            if (!tocaba(hid, d)) continue;
            prog++;
            if (estado(hid, d) == DiaEstado.hecho) cumpl++;
          }
          salida.add(SeguimientoHabito(
            nombre: h['nombre'] as String,
            emoji: h['emoji'] as String?,
            semana: semana,
            mesCumplidos: cumpl,
            mesProgramados: prog,
          ));
        }
        return salida;
      });
}

final habitosRepositoryProvider = Provider<HabitosRepository>(
  (ref) => HabitosRepository(ref.read(supabaseServiceProvider)),
);
