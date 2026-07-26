// Biblioteca maestra APROBADA de VITA (contenido curado, Dart puro).
//
// Solo comidas reales de Yurby + Juan (ver VITA_Alimentacion_Biblioteca.md).
// Macros por 100 g/ml PROVISIONALES (se afinan con datos reales). Ids por slug.
// El motor solo usa lo aprobado; nunca inventa combos.

import 'alimentacion.dart';
import 'motor.dart';

// ── Helpers de construcción ────────────────────────────────────────────────

Alimento _a(
  String id,
  String nombre,
  String categoria, {
  double kcal = 0,
  double prot = 0,
  double carb = 0,
  double grasa = 0,
  double fibra = 0,
  String unidad = 'g',
  double? gramosPorUnidad,
  double? rinde,
}) =>
    Alimento(
      id: id,
      nombre: nombre,
      categoria: categoria,
      macros100: Macros(
          kcal: kcal, prot: prot, carb: carb, grasa: grasa, fibra: fibra),
      unidad: unidad,
      gramosPorUnidad: gramosPorUnidad,
      rindeCocidoPct: rinde,
    );

Preparacion _p(
  String id,
  String nombre,
  String foodId, {
  String tipo = 'base',
  String? derivaDe,
  String frecuencia = Frecuencias.frecuente,
  bool congelable = false,
  bool mealPrep = false,
  int? tiempoMin,
  List<String> etiquetas = const [],
}) =>
    Preparacion(
      id: id,
      nombre: nombre,
      tipo: tipo,
      derivaDe: derivaDe,
      foodId: foodId,
      frecuencia: frecuencia,
      congelable: congelable,
      mealPrep: mealPrep,
      tiempoMin: tiempoMin,
      etiquetas: etiquetas,
    );

/// Ensamble con componentes. Cada componente es `('prep', id, rol)` o
/// `('food', id, rol)`. Los ids de componente se derivan del ensamble.
Ensamble _e(
  String id,
  String nombre,
  String momento,
  List<(String, String, String)> comps, {
  String frecuencia = Frecuencias.frecuente,
  String? alternativaDe,
  List<String> etiquetas = const [],
}) {
  final componentes = <ComponenteEnsamble>[];
  for (var i = 0; i < comps.length; i++) {
    final (clase, ref, rol) = comps[i];
    componentes.add(ComponenteEnsamble(
      id: '$id-$i',
      assemblyId: id,
      preparationId: clase == 'prep' ? ref : null,
      foodId: clase == 'food' ? ref : null,
      rol: rol,
      orden: i,
    ));
  }
  return Ensamble(
    id: id,
    nombre: nombre,
    momento: momento,
    frecuencia: frecuencia,
    alternativaDe: alternativaDe,
    etiquetas: etiquetas,
    componentes: componentes,
  );
}

/// La biblioteca aprobada lista para el motor.
Biblioteca bibliotecaAprobada() {
  final alimentos = <Alimento>[
    // Proteínas (macros por 100 g cocido salvo indicado)
    _a('pollo', 'Pollo', 'proteina',
        kcal: 165, prot: 31, grasa: 3.6, rinde: 70),
    _a('carne', 'Carne de vacuno', 'proteina',
        kcal: 200, prot: 27, grasa: 10, rinde: 70),
    _a('molida', 'Carne molida', 'proteina',
        kcal: 230, prot: 26, grasa: 14, rinde: 75),
    _a('atun', 'Atún', 'proteina', kcal: 130, prot: 28, grasa: 1),
    _a('salmon', 'Salmón', 'proteina', kcal: 200, prot: 22, grasa: 12),
    _a('huevo', 'Huevo', 'proteina',
        kcal: 155, prot: 13, carb: 1, grasa: 11, gramosPorUnidad: 55),
    _a('jamon', 'Jamón', 'proteina', kcal: 145, prot: 18, carb: 1.5, grasa: 7),
    // Carbohidratos
    _a('arroz', 'Arroz', 'carbohidrato',
        kcal: 130, prot: 2.7, carb: 28, grasa: 0.3, fibra: 0.4),
    _a('papa', 'Papa', 'carbohidrato',
        kcal: 87, prot: 2, carb: 20, grasa: 0.1, fibra: 1.8),
    _a('pasta', 'Pasta', 'carbohidrato',
        kcal: 158, prot: 6, carb: 31, grasa: 1, fibra: 1.8),
    _a('arepa', 'Arepa', 'carbohidrato',
        kcal: 218, prot: 5.5, carb: 45, grasa: 2.5, fibra: 2),
    _a('pan', 'Pan', 'carbohidrato',
        kcal: 265, prot: 9, carb: 49, grasa: 3.2, fibra: 2.4),
    _a('paquecas', 'Paquecas', 'carbohidrato',
        kcal: 230, prot: 6, carb: 35, grasa: 7, fibra: 1),
    _a('choclo', 'Choclo', 'carbohidrato',
        kcal: 96, prot: 3.4, carb: 21, grasa: 1.5, fibra: 2.4),
    // Verduras / frescos
    _a('lechuga', 'Lechuga', 'verdura',
        kcal: 15, prot: 1.4, carb: 2.9, fibra: 1.3),
    _a('tomate', 'Tomate', 'fresco',
        kcal: 18, prot: 0.9, carb: 3.9, fibra: 1.2),
    _a('pepino', 'Pepino', 'verdura',
        kcal: 15, prot: 0.7, carb: 3.6, fibra: 0.5),
    _a('zanahoria', 'Zanahoria', 'verdura',
        kcal: 41, prot: 0.9, carb: 10, fibra: 2.8),
    _a('brocoli', 'Brócoli', 'verdura',
        kcal: 35, prot: 2.4, carb: 7, fibra: 3.3),
    _a('pimenton', 'Pimentón', 'verdura',
        kcal: 31, prot: 1, carb: 6, fibra: 2.1),
    _a('cebolla', 'Cebolla', 'verdura',
        kcal: 40, prot: 1.1, carb: 9, fibra: 1.7),
    _a('palta', 'Palta', 'fresco',
        kcal: 160, prot: 2, carb: 9, grasa: 15, fibra: 7),
    // Lácteos
    _a('queso', 'Queso', 'lacteo', kcal: 350, prot: 25, carb: 2, grasa: 27),
    _a('quesillo', 'Quesillo', 'lacteo',
        kcal: 300, prot: 20, carb: 3, grasa: 23),
    _a('leche', 'Leche', 'lacteo',
        kcal: 62, prot: 3.2, carb: 4.8, grasa: 3.3, unidad: 'ml'),
    // Frutas
    _a('manzana', 'Manzana', 'fruta',
        kcal: 52, prot: 0.3, carb: 14, fibra: 2.4),
    _a('platano', 'Plátano', 'fruta',
        kcal: 89, prot: 1.1, carb: 23, grasa: 0.3, fibra: 2.6),
    _a('frutilla', 'Frutillas', 'fruta',
        kcal: 33, prot: 0.7, carb: 8, fibra: 2),
    _a('uva', 'Uvas', 'fruta', kcal: 69, prot: 0.7, carb: 18, fibra: 0.9),
    // Grasa
    _a('aceite', 'Aceite', 'grasa', kcal: 884, grasa: 100),
  ];

  final preparaciones = <Preparacion>[
    // Pollo: una base, dos terminaciones (no cuentan como producción nueva)
    _p('pollo_cocido', 'Pollo cocido', 'pollo',
        congelable: true,
        mealPrep: true,
        tiempoMin: 40,
        frecuencia: Frecuencias.favoritaFrecuente),
    _p('pollo_plancha', 'Pollo a la plancha', 'pollo',
        tipo: 'terminacion',
        derivaDe: 'pollo_cocido',
        congelable: true,
        mealPrep: true),
    _p('pollo_desmenuzado', 'Pollo desmenuzado', 'pollo',
        tipo: 'terminacion',
        derivaDe: 'pollo_cocido',
        congelable: true,
        mealPrep: true,
        frecuencia: Frecuencias.favoritaFrecuente),
    _p('pollo_salteado', 'Pollo salteado', 'pollo',
        tipo: 'terminacion', derivaDe: 'pollo_cocido', mealPrep: true),
    // Carne
    _p('carne_plancha', 'Carne a la plancha', 'carne', tiempoMin: 15),
    _p('bolonesa', 'Boloñesa', 'molida',
        congelable: true,
        mealPrep: true,
        tiempoMin: 30,
        etiquetas: ['económica']),
    // Otras proteínas
    _p('atun_mezcla', 'Atún con cebolla', 'atun',
        tiempoMin: 10, etiquetas: ['rápida']),
    _p('huevo_perico', 'Perico', 'huevo',
        tiempoMin: 10, frecuencia: Frecuencias.ocasional),
    _p('huevo_plancha', 'Huevo a la plancha', 'huevo',
        tiempoMin: 8, frecuencia: Frecuencias.ocasional),
    // Bases
    _p('arroz', 'Arroz', 'arroz',
        congelable: false, mealPrep: true, tiempoMin: 20),
    _p('pasta_cocida', 'Pasta', 'pasta', tiempoMin: 12),
  ];

  final ensambles = <Ensamble>[
    // Desayunos (salados)
    _e(
        'des_arepa_pollo',
        'Arepa con pollo desmenuzado',
        Momentos.desayuno,
        [
          ('food', 'arepa', 'base'),
          ('prep', 'pollo_desmenuzado', 'proteina'),
        ],
        frecuencia: Frecuencias.favoritaFrecuente),
    _e(
        'des_perico',
        'Perico con arepa',
        Momentos.desayuno,
        [
          ('prep', 'huevo_perico', 'proteina'),
          ('food', 'arepa', 'base'),
        ],
        frecuencia: Frecuencias.ocasional),
    _e('des_arepa_queso', 'Arepa con queso', Momentos.desayuno, [
      ('food', 'arepa', 'base'),
      ('food', 'queso', 'lacteo'),
    ]),
    _e(
        'des_huevo_palta',
        'Huevo a la plancha, palta y arepa',
        Momentos.desayuno,
        [
          ('prep', 'huevo_plancha', 'proteina'),
          ('food', 'palta', 'fresco'),
          ('food', 'arepa', 'base'),
        ],
        frecuencia: Frecuencias.ocasional),
    _e('des_tostada_palta', 'Tostada de palta, tomate y quesillo',
        Momentos.desayuno, [
      ('food', 'pan', 'base'),
      ('food', 'palta', 'fresco'),
      ('food', 'tomate', 'fresco'),
      ('food', 'quesillo', 'lacteo'),
    ]),
    _e('des_arepa_jamonqueso', 'Arepa con jamón y queso', Momentos.desayuno, [
      ('food', 'arepa', 'base'),
      ('food', 'jamon', 'proteina'),
      ('food', 'queso', 'lacteo'),
    ]),
    _e(
        'des_paquecas_queso',
        'Paquecas con queso',
        Momentos.desayuno,
        [
          ('food', 'paquecas', 'base'),
          ('food', 'queso', 'lacteo'),
        ],
        frecuencia: Frecuencias.ocasional),

    // Almuerzos (Lun–Vie)
    _e(
        'alm_pollo_arroz',
        'Pollo a la plancha con arroz y ensalada',
        Momentos.almuerzo,
        [
          ('prep', 'pollo_plancha', 'proteina'),
          ('prep', 'arroz', 'base'),
          ('food', 'lechuga', 'verdura'),
          ('food', 'tomate', 'fresco'),
          ('food', 'pepino', 'verdura'),
          ('food', 'zanahoria', 'verdura'),
          ('food', 'palta', 'fresco'),
          ('food', 'aceite', 'aliño'),
        ],
        frecuencia: Frecuencias.favoritaFrecuente),
    _e('alm_carne_arroz', 'Carne a la plancha con arroz y ensalada',
        Momentos.almuerzo, [
      ('prep', 'carne_plancha', 'proteina'),
      ('prep', 'arroz', 'base'),
      ('food', 'tomate', 'fresco'),
      ('food', 'pepino', 'verdura'),
      ('food', 'palta', 'fresco'),
      ('food', 'aceite', 'aliño'),
    ]),
    _e('alm_pasta_atun', 'Pasta con atún y tomate', Momentos.almuerzo, [
      ('prep', 'atun_mezcla', 'proteina'),
      ('prep', 'pasta_cocida', 'base'),
      ('food', 'tomate', 'fresco'),
    ]),
    _e('alm_pollo_salteado', 'Pollo salteado con verduras y arroz',
        Momentos.almuerzo, [
      ('prep', 'pollo_salteado', 'proteina'),
      ('prep', 'arroz', 'base'),
      ('food', 'pimenton', 'verdura'),
      ('food', 'zanahoria', 'verdura'),
      ('food', 'brocoli', 'verdura'),
    ]),
    _e('alm_bolonesa', 'Boloñesa con pasta', Momentos.almuerzo, [
      ('prep', 'bolonesa', 'proteina'),
      ('prep', 'pasta_cocida', 'base'),
      ('food', 'tomate', 'fresco'),
    ]),

    // Meriendas (solo lista aprobada)
    _e('mer_platano_leche', 'Plátano con leche', Momentos.merienda, [
      ('food', 'platano', 'fruta'),
      ('food', 'leche', 'lacteo'),
    ]),
    _e('mer_manzana', 'Manzana', Momentos.merienda, [
      ('food', 'manzana', 'fruta'),
    ]),
    _e('mer_uva', 'Uvas', Momentos.merienda, [
      ('food', 'uva', 'fruta'),
    ]),
    _e('mer_platano', 'Plátano', Momentos.merienda, [
      ('food', 'platano', 'fruta'),
    ]),
    _e(
        'mer_batido_frutilla',
        'Batido de leche con frutillas',
        Momentos.merienda,
        [
          ('food', 'leche', 'lacteo'),
          ('food', 'frutilla', 'fruta'),
        ],
        frecuencia: Frecuencias.ocasional,
        etiquetas: ['batido']),

    // Fin de semana (concreto) + sus alternativas
    _e(
        'fin_fajitas',
        'Fajitas de pollo con vegetales',
        Momentos.finde,
        [
          ('prep', 'pollo_plancha', 'proteina'),
          ('food', 'pan', 'base'),
          ('food', 'pimenton', 'verdura'),
          ('food', 'cebolla', 'verdura'),
        ],
        frecuencia: Frecuencias.soloFinde),
    _e(
        'fin_pollo_horno',
        'Pollo al horno con papas',
        Momentos.finde,
        [
          ('prep', 'pollo_plancha', 'proteina'),
          ('prep', 'arroz', 'base'),
          ('food', 'papa', 'base'),
        ],
        frecuencia: Frecuencias.soloFinde,
        alternativaDe: 'fin_fajitas'),
    _e(
        'fin_pizza',
        'Pizza casera de pollo y vegetales',
        Momentos.finde,
        [
          ('food', 'pan', 'base'),
          ('prep', 'pollo_desmenuzado', 'proteina'),
          ('food', 'queso', 'lacteo'),
          ('food', 'tomate', 'fresco'),
        ],
        frecuencia: Frecuencias.soloFinde),
    _e(
        'fin_parrilla',
        'Parrilla con ensalada y papa',
        Momentos.finde,
        [
          ('prep', 'carne_plancha', 'proteina'),
          ('food', 'papa', 'base'),
          ('food', 'tomate', 'fresco'),
          ('food', 'lechuga', 'verdura'),
        ],
        frecuencia: Frecuencias.soloFinde,
        alternativaDe: 'fin_pizza'),
  ];

  return Biblioteca(
    alimentos: alimentos,
    preparaciones: preparaciones,
    ensambles: ensambles,
  );
}

/// Perfiles provisionales por defecto (mientras no exista el perfil real).
/// Metas PROVISIONALES; se recalculan con el formulario de perfil.
List<PerfilNutricional> perfilesProvisionales() => const [
      PerfilNutricional(
        id: 'yurby',
        nombre: 'Yurby',
        sexo: 'femenino',
        objetivo: Objetivos.deficit,
        kcalObjetivo: 1550,
        protObjetivoG: 115,
        grasaMinG: 40,
        kcalToleranciaPct: 5,
        provisional: true,
      ),
      PerfilNutricional(
        id: 'juan',
        nombre: 'Juan',
        sexo: 'masculino',
        objetivo: Objetivos.deficit,
        kcalObjetivo: 2250,
        protObjetivoG: 140,
        grasaMinG: 55,
        kcalToleranciaPct: 5,
        provisional: true,
      ),
    ];
