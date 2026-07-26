// Cocina Familiar — la casa come de la misma olla, con reglas distintas.
//
//   👩 Yurby        → déficit (macros, motor)
//   👨 Juan         → mantención (macros, motor)
//   👦 Juan Miguel  → 4 años, muy selectivo → NO macros, CRECIMIENTO.
//
// Para el niño no calculamos gramos ni calorías: elegimos de SU lista corta
// (lo que sí come), reutilizando lo que ya se cocinó, y damos la **presentación**
// (guisadito, en trozos pequeños, vaso de leche). Que coma y crezca contento.

import 'motor.dart';

/// Perfil del niño (no entra al motor de macros).
const perfilJuanMiguel = (
  nombre: 'Juan Miguel',
  edad: 4,
  nota: 'Muy selectivo. Le gusta guisadito. Prioridad: que coma y crezca.',
);

/// Una comida del niño: su nombre, cómo servirla y si aprovecha la producción.
class ComidaNino {
  const ComidaNino({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.presentacion,
    this.usaProduccion = true,
  });

  final String id;
  final String nombre;
  final String emoji;
  final List<String> presentacion; // pasos de servido (no gramos)
  final bool usaProduccion; // aprovecha el pollo/arroz ya cocido
}

// Su lista corta APROBADA (lo que sí come). Guisado, blandito, trozos pequeños.
const _pollolPasta = ComidaNino(
  id: 'nino_pollo_pasta',
  nombre: 'Pollo con pasta',
  emoji: '🍗',
  presentacion: [
    'Pollo desmenuzado guisadito (del domingo)',
    'Con pasta, bien mezclado — le gusta guisado',
    'En trozos pequeños',
    'Vaso de leche 🥛',
  ],
);

const _polloArroz = ComidaNino(
  id: 'nino_pollo_arroz',
  nombre: 'Pollo con arroz',
  emoji: '🍗',
  presentacion: [
    'Pollo desmenuzado guisado',
    'Con arroz blandito',
    'En trozos pequeños',
    'Vaso de leche 🥛',
  ],
);

const _arrozPasta = ComidaNino(
  id: 'nino_arroz_pasta',
  nombre: 'Arroz con pasta',
  emoji: '🍚',
  presentacion: [
    'Arroz con pasta, blandito',
    'Un toque de salsa si quiere',
    'Vaso de leche 🥛',
  ],
);

const _panqueca = ComidaNino(
  id: 'nino_panqueca',
  nombre: 'Panquecas',
  emoji: '🥞',
  usaProduccion: false,
  presentacion: [
    'Panquecas blanditas en trocitos',
    'Con un poquito de queso',
    'Vaso de leche 🥛',
  ],
);

/// Plan del niño para la semana, alineado a lo que ya se cocina.
/// Determinista: mismo plan → mismo resultado.
List<ComidaNino> planNino(PlanSemana plan, Biblioteca biblioteca) {
  final out = <ComidaNino>[];
  for (var i = 0; i < plan.dias.length; i++) {
    final dia = plan.dias[i];
    final principal = dia.comidas.firstWhere(
      (c) => c.momento == 'almuerzo' || c.momento == 'finde',
      orElse: () => dia.comidas.first,
    );
    final hayPollo = _tienePollo(principal, biblioteca);
    // Si en casa hay pollo ese día, aprovecharlo (su favorito); si no, igual
    // come pollo del congelador o su arroz con pasta, alternando por día.
    if (hayPollo) {
      out.add(i.isEven ? _pollolPasta : _polloArroz);
    } else {
      out.add(i.isEven ? _pollolPasta : _arrozPasta);
    }
  }
  return out;
}

bool _tienePollo(ComidaPlan c, Biblioteca b) {
  for (final comp in c.ensamble.componentes) {
    final a = b.alimentoDe(comp);
    if (a != null && a.id == 'pollo') return true;
  }
  return false;
}

/// Sugerencia de desayuno del niño (su capricho seguro).
ComidaNino get desayunoNino => _panqueca;
