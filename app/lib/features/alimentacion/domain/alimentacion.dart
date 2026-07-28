// Entidades de dominio de Alimentación Inteligente (Dart puro, sin Flutter ni
// Supabase). Modelo por componentes de 3 niveles:
//   Alimento (ingrediente) → Preparacion (base|terminación) → Ensamble (comida).
//
// Las metas de un [PerfilNutricional] son calculadas y AUDITABLES; se guardan la
// fórmula, el déficit y el motivo. Son `provisional` hasta calcular con el perfil
// real. Ver docs/diseno/VITA_Alimentacion_Cerebro.md.

// ── Vocabularios (strings, como en finanzas) ───────────────────────────────
class Objetivos {
  static const deficit = 'deficit';
  static const mantencion = 'mantencion';
  static const ganancia = 'ganancia';
  static const embarazo = 'embarazo';
  static const lactancia = 'lactancia';
  static const adultoMayor = 'adulto_mayor';
}

class Frecuencias {
  static const favoritaFrecuente = 'favorita_frecuente';
  static const frecuente = 'frecuente';
  static const ocasional = 'ocasional';
  static const soloFinde = 'solo_finde';
  static const antojoPlanificado = 'antojo_planificado';
}

class Momentos {
  static const desayuno = 'desayuno';
  static const almuerzo = 'almuerzo';
  static const merienda = 'merienda';
  static const finde = 'finde';
}

/// Macros de una porción o de un total. Sumables entre sí.
class Macros {
  const Macros({
    this.kcal = 0,
    this.prot = 0,
    this.carb = 0,
    this.grasa = 0,
    this.fibra = 0,
  });

  final double kcal;
  final double prot;
  final double carb;
  final double grasa;
  final double fibra;

  Macros operator +(Macros o) => Macros(
        kcal: kcal + o.kcal,
        prot: prot + o.prot,
        carb: carb + o.carb,
        grasa: grasa + o.grasa,
        fibra: fibra + o.fibra,
      );

  /// Escala los macros por un factor (p.ej. gramos/100).
  Macros operator *(double f) => Macros(
        kcal: kcal * f,
        prot: prot * f,
        carb: carb * f,
        grasa: grasa * f,
        fibra: fibra * f,
      );

  static const cero = Macros();
}

/// Perfil nutricional de una persona (Yurby, Juan…) con metas auditables.
class PerfilNutricional {
  const PerfilNutricional({
    required this.id,
    required this.nombre,
    this.sexo,
    this.edad,
    this.estaturaCm,
    this.pesoKg,
    this.objetivo = Objetivos.deficit,
    this.actividad = 'sedentario',
    this.ritmoKgSemana,
    this.mantenimientoEstimado,
    this.deficitAplicado,
    this.kcalObjetivo,
    this.protObjetivoG,
    this.grasaMinG,
    this.carbDistPct,
    this.kcalToleranciaPct = 5,
    this.formulaUsada,
    this.motivo,
    this.fechaCalculo,
    this.provisional = true,
  });

  final String id;
  final String nombre;
  final String? sexo; // 'femenino' | 'masculino'
  final int? edad;
  final double? estaturaCm;
  final double? pesoKg;
  final String objetivo;
  final String actividad; // 'sedentario' | 'ligero' | 'moderado' | 'activo'
  final double? ritmoKgSemana;

  // Cálculo energético (auditable) --------------------------------
  final double? mantenimientoEstimado;
  final double? deficitAplicado;
  final double? kcalObjetivo;
  final double? protObjetivoG; // proteína MÍNIMA diaria
  final double? grasaMinG; // grasa mínima diaria
  final double? carbDistPct; // % de kcal a carbohidrato (el resto)
  final double kcalToleranciaPct; // ±% para "cerrar" el día
  final String? formulaUsada;
  final String? motivo;
  final DateTime? fechaCalculo;
  final bool provisional;

  /// Rango calórico aceptable del día [min, max] según la tolerancia.
  (double, double)? get rangoKcal {
    final meta = kcalObjetivo;
    if (meta == null) return null;
    final delta = meta * kcalToleranciaPct / 100;
    return (meta - delta, meta + delta);
  }

  PerfilNutricional copyWith({
    String? nombre,
    String? sexo,
    int? edad,
    double? estaturaCm,
    double? pesoKg,
    String? objetivo,
    String? actividad,
    double? ritmoKgSemana,
    double? mantenimientoEstimado,
    double? deficitAplicado,
    double? kcalObjetivo,
    double? protObjetivoG,
    double? grasaMinG,
    double? carbDistPct,
    double? kcalToleranciaPct,
    String? formulaUsada,
    String? motivo,
    DateTime? fechaCalculo,
    bool? provisional,
  }) =>
      PerfilNutricional(
        id: id,
        nombre: nombre ?? this.nombre,
        sexo: sexo ?? this.sexo,
        edad: edad ?? this.edad,
        estaturaCm: estaturaCm ?? this.estaturaCm,
        pesoKg: pesoKg ?? this.pesoKg,
        objetivo: objetivo ?? this.objetivo,
        actividad: actividad ?? this.actividad,
        ritmoKgSemana: ritmoKgSemana ?? this.ritmoKgSemana,
        mantenimientoEstimado:
            mantenimientoEstimado ?? this.mantenimientoEstimado,
        deficitAplicado: deficitAplicado ?? this.deficitAplicado,
        kcalObjetivo: kcalObjetivo ?? this.kcalObjetivo,
        protObjetivoG: protObjetivoG ?? this.protObjetivoG,
        grasaMinG: grasaMinG ?? this.grasaMinG,
        carbDistPct: carbDistPct ?? this.carbDistPct,
        kcalToleranciaPct: kcalToleranciaPct ?? this.kcalToleranciaPct,
        formulaUsada: formulaUsada ?? this.formulaUsada,
        motivo: motivo ?? this.motivo,
        fechaCalculo: fechaCalculo ?? this.fechaCalculo,
        provisional: provisional ?? this.provisional,
      );

  factory PerfilNutricional.fromMap(Map<String, dynamic> m) =>
      PerfilNutricional(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        sexo: m['sexo'] as String?,
        edad: (m['edad'] as num?)?.toInt(),
        estaturaCm: (m['estatura_cm'] as num?)?.toDouble(),
        pesoKg: (m['peso_kg'] as num?)?.toDouble(),
        objetivo: (m['objetivo'] as String?) ?? Objetivos.deficit,
        actividad: (m['actividad'] as String?) ?? 'sedentario',
        ritmoKgSemana: (m['ritmo_kg_semana'] as num?)?.toDouble(),
        mantenimientoEstimado:
            (m['mantenimiento_estimado'] as num?)?.toDouble(),
        deficitAplicado: (m['deficit_aplicado'] as num?)?.toDouble(),
        kcalObjetivo: (m['kcal_objetivo'] as num?)?.toDouble(),
        protObjetivoG: (m['prot_objetivo_g'] as num?)?.toDouble(),
        grasaMinG: (m['grasa_min_g'] as num?)?.toDouble(),
        carbDistPct: (m['carb_dist_pct'] as num?)?.toDouble(),
        kcalToleranciaPct: (m['kcal_tolerancia_pct'] as num?)?.toDouble() ?? 5,
        formulaUsada: m['formula_usada'] as String?,
        motivo: m['motivo'] as String?,
        fechaCalculo: m['fecha_calculo'] == null
            ? null
            : DateTime.parse(m['fecha_calculo'] as String),
        provisional: (m['provisional'] as bool?) ?? true,
      );
}

/// Un ingrediente, con macros por 100 g (o por 100 ml).
class Alimento {
  const Alimento({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.macros100 = Macros.cero,
    this.unidad = 'g',
    this.gramosPorUnidad,
    this.rindeCocidoPct,
    this.precioClp,
    this.precioPor,
    this.aprobado = true,
  });

  final String id;
  final String nombre;
  final String
      categoria; // proteina|carbohidrato|verdura|fruta|lacteo|fresco|despensa|grasa|otro
  final Macros macros100; // por 100 g / 100 ml
  final String unidad; // 'g' | 'ml' | 'unidad'
  final double? gramosPorUnidad; // 1 huevo ≈ 55 g, 1 arepa ≈ 150 g
  final double? rindeCocidoPct; // crudo→cocido (pollo ≈ 70)
  final double? precioClp;
  final String? precioPor; // 'g'|'kg'|'ml'|'l'|'unidad'
  final bool aprobado;

  /// Macros para una cantidad dada en la unidad base (g o ml).
  Macros macrosPara(double cantidad) => macros100 * (cantidad / 100);

  factory Alimento.fromMap(Map<String, dynamic> m) => Alimento(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        categoria: m['categoria'] as String,
        macros100: Macros(
          kcal: (m['kcal_100'] as num?)?.toDouble() ?? 0,
          prot: (m['prot_100'] as num?)?.toDouble() ?? 0,
          carb: (m['carb_100'] as num?)?.toDouble() ?? 0,
          grasa: (m['grasa_100'] as num?)?.toDouble() ?? 0,
          fibra: (m['fibra_100'] as num?)?.toDouble() ?? 0,
        ),
        unidad: (m['unidad'] as String?) ?? 'g',
        gramosPorUnidad: (m['gramos_por_unidad'] as num?)?.toDouble(),
        rindeCocidoPct: (m['rinde_cocido_pct'] as num?)?.toDouble(),
        precioClp: (m['precio_clp'] as num?)?.toDouble(),
        precioPor: m['precio_por'] as String?,
        aprobado: (m['aprobado'] as bool?) ?? true,
      );
}

/// Una preparación que se cocina en tanda. Puede ser `base` (se cuece una vez) o
/// `terminacion` (deriva de una base; no cuenta como producción nueva).
class Preparacion {
  const Preparacion({
    required this.id,
    required this.nombre,
    this.tipo = 'base',
    this.derivaDe,
    this.foodId,
    this.frecuencia = Frecuencias.frecuente,
    this.congelable = false,
    this.mealPrep = false,
    this.tiempoMin,
    this.etiquetas = const [],
    this.notas,
    this.aprobado = true,
  });

  final String id;
  final String nombre;
  final String tipo; // 'base' | 'terminacion'
  final String? derivaDe; // id de la preparación base
  final String? foodId; // proteína/base principal
  final String frecuencia;
  final bool congelable;
  final bool mealPrep;
  final int? tiempoMin;
  final List<String> etiquetas;
  final String? notas;
  final bool aprobado;

  bool get esBase => tipo == 'base';
  bool get esTerminacion => tipo == 'terminacion';

  factory Preparacion.fromMap(Map<String, dynamic> m) => Preparacion(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        tipo: (m['tipo'] as String?) ?? 'base',
        derivaDe: m['deriva_de'] as String?,
        foodId: m['food_id'] as String?,
        frecuencia: (m['frecuencia'] as String?) ?? Frecuencias.frecuente,
        congelable: (m['congelable'] as bool?) ?? false,
        mealPrep: (m['meal_prep'] as bool?) ?? false,
        tiempoMin: (m['tiempo_min'] as num?)?.toInt(),
        etiquetas:
            (m['etiquetas'] as List?)?.map((e) => e as String).toList() ??
                const [],
        notas: m['notas'] as String?,
        aprobado: (m['aprobado'] as bool?) ?? true,
      );
}

/// Una comida servida, compuesta por preparaciones y/o alimentos sueltos.
class Ensamble {
  const Ensamble({
    required this.id,
    required this.nombre,
    required this.momento,
    this.descripcion,
    this.emoji,
    this.queEs,
    this.pasos = const [],
    this.calificacion,
    this.tiempoMin,
    this.frecuencia = Frecuencias.frecuente,
    this.etiquetas = const [],
    this.estado = 'ok',
    this.alternativaDe,
    this.notas,
    this.aprobado = true,
    this.componentes = const [],
  });

  final String id;
  final String nombre;
  final String momento; // desayuno|almuerzo|merienda|finde
  final String? descripcion; // acompañamiento apetitoso ("con arroz al ajo…")
  final String? emoji; // ícono de la comida ("🍗")
  final String? queEs; // qué es este plato, en una frase clara
  final List<String> pasos; // cómo se prepara, paso a paso
  final double? calificacion; // qué tan bien calificada (0–5)
  final int? tiempoMin; // tiempo aproximado de preparación
  final String frecuencia;
  final List<String> etiquetas; // 'fácil' · 'económica' · 'saludable'…
  final String estado; // ok|ajustar|quitar
  final String? alternativaDe; // ensamble del que es plan B
  final String? notas;
  final bool aprobado;
  final List<ComponenteEnsamble> componentes;

  factory Ensamble.fromMap(
    Map<String, dynamic> m, {
    List<ComponenteEnsamble> componentes = const [],
  }) =>
      Ensamble(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        momento: m['momento'] as String,
        descripcion: m['descripcion'] as String?,
        emoji: m['emoji'] as String?,
        queEs: m['que_es'] as String?,
        pasos:
            (m['pasos'] as List?)?.map((e) => e as String).toList() ?? const [],
        calificacion: (m['calificacion'] as num?)?.toDouble(),
        tiempoMin: (m['tiempo_min'] as num?)?.toInt(),
        frecuencia: (m['frecuencia'] as String?) ?? Frecuencias.frecuente,
        etiquetas:
            (m['etiquetas'] as List?)?.map((e) => e as String).toList() ??
                const [],
        estado: (m['estado'] as String?) ?? 'ok',
        alternativaDe: m['alternativa_de'] as String?,
        notas: m['notas'] as String?,
        aprobado: (m['aprobado'] as bool?) ?? true,
        componentes: componentes,
      );
}

/// Un componente de un ensamble: una preparación O un alimento suelto.
class ComponenteEnsamble {
  const ComponenteEnsamble({
    required this.id,
    required this.assemblyId,
    this.preparationId,
    this.foodId,
    this.rol = 'base',
    this.obligatorio = true,
    this.orden = 0,
  });

  final String id;
  final String assemblyId;
  final String? preparationId;
  final String? foodId;
  final String rol; // proteina|base|verdura|fresco|aliño|lacteo|fruta
  final bool obligatorio;
  final int orden;

  bool get esPreparacion => preparationId != null;

  factory ComponenteEnsamble.fromMap(Map<String, dynamic> m) =>
      ComponenteEnsamble(
        id: m['id'] as String,
        assemblyId: m['assembly_id'] as String,
        preparationId: m['preparation_id'] as String?,
        foodId: m['food_id'] as String?,
        rol: (m['rol'] as String?) ?? 'base',
        obligatorio: (m['obligatorio'] as bool?) ?? true,
        orden: (m['orden'] as num?)?.toInt() ?? 0,
      );
}

/// Afinidad aprendida por persona sobre un ensamble o preparación.
class Afinidad {
  const Afinidad({
    required this.id,
    required this.persona,
    this.assemblyId,
    this.preparationId,
    this.rating,
    this.afinidad = 0,
    this.vecesSugerido = 0,
    this.vecesAceptado = 0,
    this.vecesRechazado = 0,
    this.ultimoContexto,
  });

  final String id;
  final String persona;
  final String? assemblyId;
  final String? preparationId;
  final String?
      rating; // me_encanta|me_gusta|me_da_igual|solo_ocasional|no_me_gusta|nunca_sugerir
  final double afinidad;
  final int vecesSugerido;
  final int vecesAceptado;
  final int vecesRechazado;
  final String? ultimoContexto;

  factory Afinidad.fromMap(Map<String, dynamic> m) => Afinidad(
        id: m['id'] as String,
        persona: m['persona'] as String,
        assemblyId: m['assembly_id'] as String?,
        preparationId: m['preparation_id'] as String?,
        rating: m['rating'] as String?,
        afinidad: (m['afinidad'] as num?)?.toDouble() ?? 0,
        vecesSugerido: (m['veces_sugerido'] as num?)?.toInt() ?? 0,
        vecesAceptado: (m['veces_aceptado'] as num?)?.toInt() ?? 0,
        vecesRechazado: (m['veces_rechazado'] as num?)?.toInt() ?? 0,
        ultimoContexto: m['ultimo_contexto'] as String?,
      );
}

/// Un ítem en la despensa: qué hay, dónde y hasta cuándo.
class ItemDespensa {
  const ItemDespensa({
    required this.id,
    required this.nombre,
    this.foodId,
    this.cantidad,
    this.unidad = 'g',
    this.ubicacion = 'despensa',
    this.consumirPrimero = false,
    required this.fechaIngreso,
    this.fechaVencimiento,
  });

  final String id;
  final String nombre;
  final String? foodId;
  final double? cantidad;
  final String unidad; // g|ml|unidad
  final String ubicacion; // despensa|refri|congelador
  final bool consumirPrimero;
  final DateTime fechaIngreso;
  final DateTime? fechaVencimiento;

  factory ItemDespensa.fromMap(Map<String, dynamic> m) => ItemDespensa(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        foodId: m['food_id'] as String?,
        cantidad: (m['cantidad'] as num?)?.toDouble(),
        unidad: (m['unidad'] as String?) ?? 'g',
        ubicacion: (m['ubicacion'] as String?) ?? 'despensa',
        consumirPrimero: (m['consumir_primero'] as bool?) ?? false,
        fechaIngreso: DateTime.parse(m['fecha_ingreso'] as String),
        fechaVencimiento: m['fecha_vencimiento'] == null
            ? null
            : DateTime.parse(m['fecha_vencimiento'] as String),
      );
}

/// Un registro de peso (se lee como tendencia, no como dato aislado).
class RegistroPeso {
  const RegistroPeso({
    required this.id,
    required this.persona,
    required this.fecha,
    required this.pesoKg,
    this.nota,
  });

  final String id;
  final String persona;
  final DateTime fecha;
  final double pesoKg;
  final String? nota;

  factory RegistroPeso.fromMap(Map<String, dynamic> m) => RegistroPeso(
        id: m['id'] as String,
        persona: m['persona'] as String,
        fecha: DateTime.parse(m['fecha'] as String),
        pesoKg: (m['peso_kg'] as num).toDouble(),
        nota: m['nota'] as String?,
      );
}

/// Una compra: un viaje al supermercado en una fecha, con su monto. Su gasto se
/// registra en Finanzas (`financeTxId`) para dejar el rastro entre módulos.
class Compra {
  const Compra({
    required this.id,
    this.tipo = 'quincenal',
    this.supermercado,
    required this.fecha,
    this.periodoInicio,
    this.periodoFin,
    this.monto,
    this.estado = 'planificada',
    this.financeTxId,
    this.presupuesto,
    this.nota,
  });

  final String id;
  final String tipo; // quincenal | reposicion
  final String? supermercado;
  final DateTime fecha;
  final DateTime? periodoInicio;
  final DateTime? periodoFin;
  final double? monto; // total, editable
  final String estado; // planificada | comprada
  final String? financeTxId; // gasto asociado en Finanzas
  final double? presupuesto;
  final String? nota;

  bool get comprada => estado == 'comprada';

  factory Compra.fromMap(Map<String, dynamic> m) => Compra(
        id: m['id'] as String,
        tipo: (m['tipo'] as String?) ?? 'quincenal',
        supermercado: m['supermercado'] as String?,
        fecha: DateTime.parse(m['fecha'] as String),
        periodoInicio: m['periodo_inicio'] == null
            ? null
            : DateTime.parse(m['periodo_inicio'] as String),
        periodoFin: m['periodo_fin'] == null
            ? null
            : DateTime.parse(m['periodo_fin'] as String),
        monto: (m['monto'] as num?)?.toDouble(),
        estado: (m['estado'] as String?) ?? 'planificada',
        financeTxId: m['finance_tx_id'] as String?,
        presupuesto: (m['presupuesto'] as num?)?.toDouble(),
        nota: m['nota'] as String?,
      );
}

/// Un ítem de una compra, con su precio y estado (falta / en carro / comprado).
class CompraItem {
  const CompraItem({
    required this.id,
    required this.compraId,
    this.foodId,
    required this.nombre,
    this.categoria,
    this.cantidad,
    this.unidad,
    this.precio,
    this.estado = 'falta',
    this.yaTengo = false,
    this.sustituto,
  });

  final String id;
  final String compraId;
  final String? foodId;
  final String nombre;
  final String? categoria;
  final double? cantidad;
  final String? unidad; // unidad humana: kg · u · litro · paquete
  final double? precio;
  final String estado; // falta | en_carro | comprado
  final bool yaTengo;
  final String? sustituto;

  factory CompraItem.fromMap(Map<String, dynamic> m) => CompraItem(
        id: m['id'] as String,
        compraId: m['compra_id'] as String,
        foodId: m['food_id'] as String?,
        nombre: m['nombre'] as String,
        categoria: m['categoria'] as String?,
        cantidad: (m['cantidad'] as num?)?.toDouble(),
        unidad: m['unidad'] as String?,
        precio: (m['precio'] as num?)?.toDouble(),
        estado: (m['estado'] as String?) ?? 'falta',
        yaTengo: (m['ya_tengo'] as bool?) ?? false,
        sustituto: m['sustituto'] as String?,
      );
}

/// La decisión de la usuaria sobre una comida de un día: si la comió, y si la
/// cambió por otra. El plan es determinista; esto guarda solo el override.
class EstadoComida {
  const EstadoComida({
    required this.fecha,
    required this.momento,
    this.assemblyId,
    this.estado = 'planeado',
  });

  final DateTime fecha;
  final String momento; // desayuno | almuerzo | merienda | finde
  final String? assemblyId; // comida elegida (si la cambió)
  final String estado; // planeado | comido | no_comido

  bool get comido => estado == 'comido';
  bool get noComido => estado == 'no_comido';

  static String claveDe(DateTime fecha, String momento) {
    final mm = fecha.month.toString().padLeft(2, '0');
    final dd = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mm-$dd|$momento';
  }

  String get clave => claveDe(fecha, momento);

  factory EstadoComida.fromMap(Map<String, dynamic> m) => EstadoComida(
        fecha: DateTime.parse(m['fecha'] as String),
        momento: m['momento'] as String,
        assemblyId: m['assembly_id'] as String?,
        estado: (m['estado'] as String?) ?? 'planeado',
      );
}

/// La sesión de cocción (meal prep) de una semana: si ya se cocinó y cuándo.
class CocinaSesion {
  const CocinaSesion({
    required this.semanaInicio,
    this.cocinadaAt,
    this.nota,
  });

  final DateTime semanaInicio; // lunes de la semana
  final DateTime? cocinadaAt; // null = pendiente

  final String? nota;

  bool get cocinada => cocinadaAt != null;

  factory CocinaSesion.fromMap(Map<String, dynamic> m) => CocinaSesion(
        semanaInicio: DateTime.parse(m['semana_inicio'] as String),
        cocinadaAt: m['cocinada_at'] == null
            ? null
            : DateTime.parse(m['cocinada_at'] as String).toLocal(),
        nota: m['nota'] as String?,
      );
}

/// Traduce una cantidad en gramos/ml a una referencia VISUAL (sin balanza):
/// taza, palma, puño, unidad, cucharada. Es aproximado a propósito — orienta,
/// no pesa. La usuaria pidió medidas gráficas, no gramos.
String porcionVisual(Alimento a, double cantidad) {
  if (cantidad <= 0) return '';
  // Contables por unidad natural: huevos, arepas, frutas. Recibe gramos y los
  // pasa a unidades con gramosPorUnidad (1 huevo ≈ 55 g).
  if (a.unidad == 'unidad') {
    final porUnidad = a.gramosPorUnidad ?? 1;
    final n = (cantidad / porUnidad).round().clamp(1, 99);
    final nombre = a.nombre.toLowerCase();
    return n == 1 ? '1 $nombre' : '$n ${nombre}s';
  }
  switch (a.categoria) {
    case 'proteina':
      return _aprox(cantidad / 100, 'palma', 'palmas'); // 1 palma ≈ 100 g
    case 'carbohidrato':
      return _aprox(cantidad / 180, 'taza', 'tazas'); // 1 taza ≈ 180 g cocido
    case 'verdura':
      return _aprox(cantidad / 80, 'puñado', 'puñados');
    case 'fruta':
      return _aprox(cantidad / 120, 'porción', 'porciones');
    case 'lacteo':
      if (a.unidad == 'ml') return cantidad >= 200 ? '1 vaso' : '½ vaso';
      return _aprox(cantidad / 30, 'lonja', 'lonjas'); // 1 lonja ≈ 30 g
    case 'fresco':
      final n = a.nombre.toLowerCase();
      return _aprox(cantidad / 100, n, '${n}s');
    case 'grasa':
      return _aprox(cantidad / 12, 'cucharada', 'cucharadas'); // 1 cda ≈ 12 g
    default:
      return '${cantidad.round()} g';
  }
}

/// Redondea a media unidad y lo dice en humano: ½, 1, 1½, 2…
String _aprox(double n, String uno, String varios) {
  final medios = (n * 2).round().clamp(1, 200);
  final entero = medios ~/ 2;
  final mitad = medios.isOdd;
  if (medios == 1) return '½ $uno';
  final numero = mitad ? '$entero½' : '$entero';
  final palabra = (entero == 1 && !mitad) ? uno : varios;
  return '$numero $palabra';
}
