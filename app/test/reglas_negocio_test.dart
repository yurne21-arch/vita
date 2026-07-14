import 'package:flutter_test/flutter_test.dart';
import 'package:vita/core/content/versiculos.dart';
import 'package:vita/core/widgets/errores.dart';
import 'package:vita/features/mi_vida/data/prioridades_repository.dart';
import 'package:vita/features/proyectos/data/projects_repository.dart';

/// Las reglas de negocio nacen con su prueba (Constitución Técnica §8).
void main() {
  final ahora = DateTime(2026, 1, 1);

  group('Progreso de proyecto', () {
    Project proyecto({int? progresoManual}) => Project(
          id: 'p1',
          titulo: 'Proyecto',
          progresoManual: progresoManual,
          createdAt: ahora,
          updatedAt: ahora,
        );

    ProjectTask paso(String id, {bool completada = false}) => ProjectTask(
          id: id,
          projectId: 'p1',
          texto: 'Paso $id',
          completada: completada,
          createdAt: ahora,
        );

    ProjectTask hito(String id, {bool completada = false}) => ProjectTask(
          id: id,
          projectId: 'p1',
          texto: 'Hito $id',
          tipo: 'hito',
          completada: completada,
          createdAt: ahora,
        );

    test('sin pasos y sin progreso manual, es 0 (nunca 100)', () {
      expect(proyecto().progresoCon(const []), 0);
    });

    test('sin pasos, cae en el progreso manual si existe', () {
      expect(proyecto(progresoManual: 40).progresoCon(const []), 40);
    });

    test('se calcula solo con los pasos completados', () {
      final tareas = [paso('1', completada: true), paso('2')];
      expect(proyecto().progresoCon(tareas), 50);
    });

    test('los hitos no cuentan para el progreso', () {
      // Un hito completado no debe inflar el progreso: solo miden los pasos.
      final tareas = [paso('1'), hito('2', completada: true)];
      expect(proyecto().progresoCon(tareas), 0);
      expect(proyecto().tienePasos(tareas), isTrue);
    });

    test('un proyecto solo con hitos no tiene pasos', () {
      expect(proyecto().tienePasos([hito('1')]), isFalse);
    });

    test('todos los pasos completos son 100', () {
      final tareas = [paso('1', completada: true), paso('2', completada: true)];
      expect(proyecto().progresoCon(tareas), 100);
    });
  });

  group('Prioridades del día', () {
    test('el tope es 3 (lo garantiza también un trigger en la base)', () {
      expect(PrioridadesRepository.maximoPorDia, 3);
    });
  });

  group('Versículo del día', () {
    test('el mismo día siempre da el mismo versículo', () {
      final a = versiculoDelDia(DateTime(2026, 3, 15));
      final b = versiculoDelDia(DateTime(2026, 3, 15));
      expect(a.cita, b.cita);
      expect(a.texto, b.texto);
    });

    test('días distintos dan versículos distintos', () {
      final hoy = versiculoDelDia(DateTime(2026, 3, 15));
      final manana = versiculoDelDia(DateTime(2026, 3, 16));
      expect(hoy.cita, isNot(manana.cita));
    });

    test('nunca queda vacío, ningún día del año', () {
      for (var i = 0; i < 366; i++) {
        final v = versiculoDelDia(DateTime(2028, 1, 1).add(Duration(days: i)));
        expect(v.texto, isNotEmpty);
        expect(v.cita, isNotEmpty);
      }
    });
  });

  group('Mensajes de error', () {
    test('un mensaje de dominio llega tal cual a la usuaria', () {
      // El texto del trigger 'Máximo 3 prioridades por día' debe verse íntegro.
      const e = PrioridadesException('Máximo 3 prioridades por día');
      expect(mensajeDeError(e), 'Máximo 3 prioridades por día');
    });

    test('un error técnico nunca se le muestra en crudo', () {
      final e = Exception('PostgrestException(statusCode: 400)');
      final mensaje = mensajeDeError(e);
      expect(mensaje, isNot(contains('statusCode')));
      expect(mensaje, isNot(contains('Exception')));
    });
  });
}
