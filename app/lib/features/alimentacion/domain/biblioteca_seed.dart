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
  String? descripcion,
  String? emoji,
  String? queEs,
  List<String> pasos = const [],
  double? calificacion,
  int? tiempoMin,
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
    descripcion: descripcion,
    emoji: emoji,
    queEs: queEs,
    pasos: pasos,
    calificacion: calificacion,
    tiempoMin: tiempoMin,
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
    _a('paquecas', 'Panquecas', 'carbohidrato',
        kcal: 230, prot: 6, carb: 35, grasa: 7, fibra: 1),
    _a('choclo', 'Maíz (jojoto)', 'carbohidrato',
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
    _a('palta', 'Aguacate', 'fresco',
        kcal: 160, prot: 2, carb: 9, grasa: 15, fibra: 7),
    // Lácteos
    _a('queso', 'Queso', 'lacteo', kcal: 350, prot: 25, carb: 2, grasa: 27),
    _a('quesillo', 'Queso blanco', 'lacteo',
        kcal: 300, prot: 20, carb: 3, grasa: 23),
    _a('leche', 'Leche', 'lacteo',
        kcal: 62, prot: 3.2, carb: 4.8, grasa: 3.3, unidad: 'ml'),
    // Frutas
    _a('manzana', 'Manzana', 'fruta',
        kcal: 52, prot: 0.3, carb: 14, fibra: 2.4),
    _a('platano', 'Plátano', 'fruta',
        kcal: 89, prot: 1.1, carb: 23, grasa: 0.3, fibra: 2.6),
    _a('frutilla', 'Fresas', 'fruta', kcal: 33, prot: 0.7, carb: 8, fibra: 2),
    _a('uva', 'Uvas', 'fruta', kcal: 69, prot: 0.7, carb: 18, fibra: 0.9),
    _a('maracuya', 'Maracuyá', 'fruta',
        kcal: 97, prot: 2.2, carb: 23, fibra: 10),
    // Grasa / especiales de fin de semana
    _a('aceite', 'Aceite', 'grasa', kcal: 884, grasa: 100),
    _a('mantequilla', 'Mantequilla', 'grasa', kcal: 717, prot: 0.9, grasa: 81),
    _a('limon', 'Limón', 'fresco', kcal: 29, prot: 1.1, carb: 9, fibra: 2.8),
    _a('almendras', 'Almendras', 'grasa',
        kcal: 579, prot: 21, carb: 22, grasa: 50, fibra: 12),
    _a('esparragos', 'Espárragos', 'verdura',
        kcal: 20, prot: 2.2, carb: 3.9, fibra: 2.1),
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
    _p('carne_horno', 'Carne al horno', 'carne',
        tiempoMin: 60, frecuencia: Frecuencias.soloFinde),
    // Pescado (fin de semana)
    _p('salmon_horno', 'Salmón al horno', 'salmon',
        tiempoMin: 25, frecuencia: Frecuencias.soloFinde),
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
    // ── Desayunos (venezolanos, salados) ──
    _e(
        'des_arepa_pollo',
        'Arepa rellena de pollo',
        Momentos.desayuno,
        [
          ('food', 'arepa', 'base'),
          ('prep', 'pollo_desmenuzado', 'proteina'),
        ],
        descripcion: 'pollo desmenuzado y jugoso',
        queEs:
            'Arepa de maíz recién asada, abierta y rellena con pollo desmenuzado jugoso. El desayuno venezolano de siempre.',
        pasos: [
          'Amasa la harina de maíz con agua tibia y sal hasta que no se pegue en las manos.',
          'Forma las arepas y ásalas en budare o sartén ~7 min por lado, hasta que suenen huecas.',
          'Ábrelas por un lado y rellénalas con el pollo desmenuzado caliente.',
        ],
        calificacion: 4.8,
        tiempoMin: 25,
        emoji: '🫓',
        frecuencia: Frecuencias.favoritaFrecuente,
        etiquetas: ['fácil', 'económica']),
    _e(
        'des_perico',
        'Perico venezolano',
        Momentos.desayuno,
        [
          ('prep', 'huevo_perico', 'proteina'),
          ('food', 'arepa', 'base'),
        ],
        descripcion: 'huevo revuelto con tomate y cebolla, con arepa',
        queEs:
            'Huevos revueltos con tomate y cebolla sofritos — el perico de toda la vida, acompañado de arepa.',
        pasos: [
          'Sofríe cebolla y tomate picados en un poco de aceite hasta que ablanden.',
          'Agrega los huevos batidos y revuelve a fuego bajo hasta que cuajen.',
          'Sirve con arepa caliente.',
        ],
        calificacion: 4.6,
        tiempoMin: 12,
        emoji: '🍳',
        frecuencia: Frecuencias.ocasional,
        etiquetas: ['fácil', 'económica']),
    _e(
        'des_arepa_queso',
        'Arepa con queso',
        Momentos.desayuno,
        [
          ('food', 'arepa', 'base'),
          ('food', 'queso', 'lacteo'),
        ],
        descripcion: 'sencilla y reconfortante',
        queEs:
            'Arepa caliente rellena de queso que se derrite adentro. Simple y reconfortante.',
        pasos: [
          'Asa la arepa hasta que esté doradita y suene hueca.',
          'Ábrela y pon el queso en rebanadas dentro.',
          'Ciérrala un momento para que el calor lo derrita.',
        ],
        calificacion: 4.5,
        tiempoMin: 20,
        emoji: '🧀',
        etiquetas: ['fácil', 'económica']),
    _e(
        'des_huevo_palta',
        'Huevo con aguacate y arepa',
        Momentos.desayuno,
        [
          ('prep', 'huevo_plancha', 'proteina'),
          ('food', 'palta', 'fresco'),
          ('food', 'arepa', 'base'),
        ],
        descripcion: 'cremoso, salado, para empezar el día',
        queEs:
            'Huevo a la plancha con aguacate cremoso y arepa. Salado y suave para empezar el día.',
        pasos: [
          'Cocina el huevo a la plancha al punto que te guste.',
          'Corta el aguacate en láminas y sálalo.',
          'Sirve con la arepa caliente.',
        ],
        calificacion: 4.5,
        tiempoMin: 12,
        emoji: '🥑',
        frecuencia: Frecuencias.ocasional,
        etiquetas: ['fácil', 'saludable']),
    _e(
        'des_tostada_palta',
        'Tostada de aguacate',
        Momentos.desayuno,
        [
          ('food', 'pan', 'base'),
          ('food', 'palta', 'fresco'),
          ('food', 'tomate', 'fresco'),
          ('food', 'quesillo', 'lacteo'),
        ],
        descripcion: 'con tomate y queso blanco fresco',
        queEs:
            'Pan tostado con aguacate pisado, tomate y queso blanco fresco. Liviano y fresco.',
        pasos: [
          'Tuesta el pan.',
          'Pisa el aguacate con un poco de sal y limón y úntalo sobre el pan.',
          'Corona con rodajas de tomate y queso blanco.',
        ],
        calificacion: 4.4,
        tiempoMin: 10,
        emoji: '🥑',
        etiquetas: ['fácil', 'saludable']),
    _e(
        'des_arepa_jamonqueso',
        'Arepa de jamón y queso',
        Momentos.desayuno,
        [
          ('food', 'arepa', 'base'),
          ('food', 'jamon', 'proteina'),
          ('food', 'queso', 'lacteo'),
        ],
        descripcion: 'el clásico que nunca falla',
        queEs: 'La arepa clásica rellena de jamón y queso. La que nunca falla.',
        pasos: [
          'Asa la arepa hasta dorar.',
          'Ábrela y rellénala con jamón y queso.',
          'Caliéntala un momento para que se una todo.',
        ],
        calificacion: 4.6,
        tiempoMin: 20,
        emoji: '🥪',
        etiquetas: ['fácil', 'económica']),
    _e(
        'des_paquecas_queso',
        'Panquecas con queso',
        Momentos.desayuno,
        [
          ('food', 'paquecas', 'base'),
          ('food', 'queso', 'lacteo'),
        ],
        descripcion: 'esponjosas, para consentirte',
        queEs:
            'Panquecas esponjosas dobladas con queso adentro. Un desayuno para consentirse.',
        pasos: [
          'Mezcla harina, huevo y leche hasta una masa suave sin grumos.',
          'Cocina cada panqueca en sartén ligeramente engrasado; voltea cuando burbujee.',
          'Rellena con queso y dóblala.',
        ],
        calificacion: 4.5,
        tiempoMin: 20,
        emoji: '🥞',
        frecuencia: Frecuencias.ocasional,
        etiquetas: ['fácil']),

    // ── Almuerzos entre semana (Lun–Vie) ──
    _e(
        'alm_pollo_arroz',
        'Pollo mediterráneo',
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
        descripcion: 'con arroz al ajo y ensalada fresca',
        queEs:
            'Pechuga de pollo a la plancha con toque de ajo y limón, arroz y ensalada fresca. Ligero y con buena proteína.',
        pasos: [
          'Sazona el pollo con ajo, sal, pimienta y un chorrito de limón; hazlo a la plancha ~6 min por lado.',
          'Cocina el arroz con un diente de ajo para darle sabor.',
          'Arma la ensalada con lechuga, tomate, pepino, zanahoria y aguacate; aliña con un hilo de aceite de oliva.',
        ],
        calificacion: 4.7,
        tiempoMin: 30,
        emoji: '🍗',
        frecuencia: Frecuencias.favoritaFrecuente,
        etiquetas: ['saludable']),
    _e(
        'alm_carne_arroz',
        'Carne a la plancha',
        Momentos.almuerzo,
        [
          ('prep', 'carne_plancha', 'proteina'),
          ('prep', 'arroz', 'base'),
          ('food', 'tomate', 'fresco'),
          ('food', 'pepino', 'verdura'),
          ('food', 'palta', 'fresco'),
          ('food', 'aceite', 'aliño'),
        ],
        descripcion: 'con arroz blanco y ensalada de la casa',
        queEs:
            'Bistec de res a la plancha, jugoso, con arroz blanco y ensalada de la casa.',
        pasos: [
          'Sazona la carne con sal y pimienta; séllala en plancha bien caliente 3–4 min por lado.',
          'Déjala reposar 3 min antes de cortar para que quede jugosa.',
          'Sirve con arroz y ensalada de tomate, pepino y aguacate.',
        ],
        calificacion: 4.6,
        tiempoMin: 25,
        emoji: '🥩',
        etiquetas: ['saludable']),
    _e(
        'alm_pasta_atun',
        'Pasta marinera de atún',
        Momentos.almuerzo,
        [
          ('prep', 'atun_mezcla', 'proteina'),
          ('prep', 'pasta_cocida', 'base'),
          ('food', 'tomate', 'fresco'),
        ],
        descripcion: 'con tomate natural',
        queEs:
            'Pasta con atún y tomate natural. Rápida, rendidora y económica.',
        pasos: [
          'Cocina la pasta al dente en agua con sal.',
          'Sofríe tomate picado y suma el atún escurrido.',
          'Mezcla con la pasta y sirve.',
        ],
        calificacion: 4.3,
        tiempoMin: 20,
        emoji: '🍝',
        etiquetas: ['económica', 'rápida']),
    _e(
        'alm_pollo_salteado',
        'Pollo salteado con vegetales',
        Momentos.almuerzo,
        [
          ('prep', 'pollo_salteado', 'proteina'),
          ('prep', 'arroz', 'base'),
          ('food', 'pimenton', 'verdura'),
          ('food', 'zanahoria', 'verdura'),
          ('food', 'brocoli', 'verdura'),
        ],
        descripcion: 'con verduras crocantes y arroz',
        queEs:
            'Tiras de pollo salteadas con pimentón, zanahoria y brócoli crocantes, servidas sobre arroz.',
        pasos: [
          'Corta el pollo en tiras y saltéalo a fuego alto hasta dorar.',
          'Agrega los vegetales y saltea 4–5 min para que queden crocantes.',
          'Sirve sobre el arroz.',
        ],
        calificacion: 4.5,
        tiempoMin: 25,
        emoji: '🥢',
        etiquetas: ['saludable']),
    _e(
        'alm_bolonesa',
        'Pasta boloñesa',
        Momentos.almuerzo,
        [
          ('prep', 'bolonesa', 'proteina'),
          ('prep', 'pasta_cocida', 'base'),
          ('food', 'tomate', 'fresco'),
        ],
        descripcion: 'salsa de carne lenta con tomate',
        queEs:
            'Pasta con salsa de carne molida y tomate cocinada con calma. Rinde y le gusta a todos.',
        pasos: [
          'Sofríe cebolla; suma la carne molida y dórala.',
          'Agrega tomate y cocina a fuego bajo unos 20 min.',
          'Mézclala con la pasta al dente.',
        ],
        calificacion: 4.7,
        tiempoMin: 30,
        emoji: '🍝',
        etiquetas: ['económica']),

    // ── Meriendas ──
    _e(
        'mer_platano_leche',
        'Plátano con leche',
        Momentos.merienda,
        [
          ('food', 'platano', 'fruta'),
          ('food', 'leche', 'lacteo'),
        ],
        queEs: 'Plátano maduro con un vaso de leche. Dulce natural y energía.',
        pasos: ['Pela y corta el plátano.', 'Acompáñalo con leche.'],
        calificacion: 4.2,
        tiempoMin: 3,
        emoji: '🥛',
        etiquetas: ['fácil']),
    _e(
        'mer_manzana',
        'Manzana fresca',
        Momentos.merienda,
        [
          ('food', 'manzana', 'fruta'),
        ],
        queEs: 'Una manzana fresca, crujiente y liviana.',
        pasos: ['Lávala y cómela entera o en gajos.'],
        calificacion: 4.0,
        tiempoMin: 1,
        emoji: '🍎',
        etiquetas: ['fácil', 'saludable']),
    _e(
        'mer_uva',
        'Uvas',
        Momentos.merienda,
        [
          ('food', 'uva', 'fruta'),
        ],
        queEs: 'Un puñado de uvas frescas, dulces y refrescantes.',
        pasos: ['Lávalas y sírvelas.'],
        calificacion: 4.0,
        tiempoMin: 1,
        emoji: '🍇',
        etiquetas: ['fácil', 'saludable']),
    _e(
        'mer_platano',
        'Plátano',
        Momentos.merienda,
        [
          ('food', 'platano', 'fruta'),
        ],
        queEs: 'Un plátano, práctico y lleno de energía.',
        pasos: ['Pélalo y cómelo.'],
        calificacion: 3.9,
        tiempoMin: 1,
        emoji: '🍌',
        etiquetas: ['fácil']),
    _e(
        'mer_batido_frutilla',
        'Batido de fresas',
        Momentos.merienda,
        [
          ('food', 'leche', 'lacteo'),
          ('food', 'frutilla', 'fruta'),
        ],
        descripcion: 'leche y fresas, cremoso',
        queEs: 'Fresas licuadas con leche, cremoso y natural.',
        pasos: ['Licúa las fresas con la leche.', 'Sirve bien frío.'],
        calificacion: 4.4,
        tiempoMin: 5,
        emoji: '🥤',
        frecuencia: Frecuencias.ocasional,
        etiquetas: ['batido', 'fácil']),

    // ── Fin de semana: comida rica y diferente (no comida rápida) ──
    _e(
        'fin_salmon',
        'Salmón al horno',
        Momentos.finde,
        [
          ('prep', 'salmon_horno', 'proteina'),
          ('food', 'papa', 'base'),
          ('food', 'mantequilla', 'aliño'),
          ('food', 'limon', 'aliño'),
          ('food', 'esparragos', 'verdura'),
          ('food', 'maracuya', 'fruta'),
        ],
        descripcion:
            'con mantequilla de ajo, papas baby, espárragos y jugo de maracuyá',
        queEs:
            'Salmón al horno con mantequilla de ajo, papas baby y espárragos, acompañado de jugo de maracuyá. Comida de fin de semana, bonita y sabrosa.',
        pasos: [
          'Unta el salmón con mantequilla de ajo, sal y unas gotas de limón.',
          'Hornéalo a 200°C unos 15 min, junto a las papas baby.',
          'Saltea los espárragos aparte y sirve con jugo de maracuyá natural.',
        ],
        calificacion: 4.9,
        tiempoMin: 35,
        emoji: '🐟',
        frecuencia: Frecuencias.soloFinde,
        etiquetas: ['saludable', 'especial']),
    _e(
        'fin_pollo_relleno',
        'Pollo relleno',
        Momentos.finde,
        [
          ('prep', 'pollo_plancha', 'proteina'),
          ('prep', 'arroz', 'base'),
          ('food', 'almendras', 'aliño'),
          ('food', 'tomate', 'fresco'),
          ('food', 'lechuga', 'verdura'),
        ],
        descripcion: 'con arroz de almendras y ensalada tropical',
        queEs:
            'Pechuga rellena, con arroz salteado con almendras y ensalada tropical. Un plato de domingo diferente.',
        pasos: [
          'Abre la pechuga tipo libro, rellénala y ciérrala con palillos.',
          'Séllala en sartén y termínala al horno ~15 min.',
          'Saltea el arroz con almendras y sirve con la ensalada.',
        ],
        calificacion: 4.6,
        tiempoMin: 40,
        emoji: '🍗',
        frecuencia: Frecuencias.soloFinde,
        alternativaDe: 'fin_salmon',
        etiquetas: ['especial']),
    _e(
        'fin_carne_horno',
        'Carne al horno',
        Momentos.finde,
        [
          ('prep', 'carne_horno', 'proteina'),
          ('food', 'papa', 'base'),
          ('food', 'queso', 'lacteo'),
          ('food', 'lechuga', 'verdura'),
          ('food', 'tomate', 'fresco'),
        ],
        descripcion: 'con papas gratinadas y ensalada',
        queEs:
            'Carne al horno tierna, con papas gratinadas y ensalada. Para compartir el fin de semana.',
        pasos: [
          'Sazona la carne y séllala en sartén para sellar los jugos.',
          'Hornéala lento hasta que esté tierna (alrededor de 1 hora).',
          'Gratina las papas con queso y arma la ensalada fresca.',
        ],
        calificacion: 4.7,
        tiempoMin: 75,
        emoji: '🥩',
        frecuencia: Frecuencias.soloFinde,
        etiquetas: ['especial']),
    _e(
        'fin_parrilla',
        'Parrilla del domingo',
        Momentos.finde,
        [
          ('prep', 'carne_plancha', 'proteina'),
          ('food', 'papa', 'base'),
          ('food', 'tomate', 'fresco'),
          ('food', 'lechuga', 'verdura'),
        ],
        descripcion: 'carnes a la parrilla, papas y ensalada',
        queEs:
            'Carnes a la parrilla con papas y ensalada. El domingo en familia.',
        pasos: [
          'Sazona las carnes solo con sal para no tapar el sabor.',
          'Ásalas a la parrilla al punto de cada quien.',
          'Acompaña con papas y ensalada fresca.',
        ],
        calificacion: 4.8,
        tiempoMin: 45,
        emoji: '🔥',
        frecuencia: Frecuencias.soloFinde,
        alternativaDe: 'fin_carne_horno',
        etiquetas: ['especial']),
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
