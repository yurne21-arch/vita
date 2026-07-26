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
        mantenimientoEstimado: mantenimientoEstimado ?? this.mantenimientoEstimado,
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

  factory PerfilNutricional.fromMap(Map<String, dynamic> m) => PerfilNutricional(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        sexo: m['sexo'] as String?,
        edad: (m['edad'] as num?)?.toInt(),
        estaturaCm: (m['estatura_cm'] as num?)?.toDouble(),
        pesoKg: (m['peso_kg'] as num?)?.toDouble(),
        objetivo: (m['objetivo'] as String?) ?? Objetivos.deficit,
        actividad: (m['actividad'] as String?) ?? 'sedentario',
        ritmoKgSemana: (m['ritmo_kg_semana'] as num?)?.toDouble(),
        mantenimientoEstimado: (m['mantenimiento_estimado'] as num?)?.toDouble(),
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
  final String categoria; // proteina|carbohidrato|verdura|fruta|lacteo|fresco|despensa|grasa|otro
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
            (m['etiquetas'] as List?)?.map((e) => e as String).toList() ?? const [],
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
  final String frecuencia;
  final List<String> etiquetas;
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
        frecuencia: (m['frecuencia'] as String?) ?? Frecuencias.frecuente,
        etiquetas:
            (m['etiquetas'] as List?)?.map((e) => e as String).toList() ?? const [],
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

  factory ComponenteEnsamble.fromMap(Map<String, dynamic> m) => ComponenteEnsamble(
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
  final String? rating; // me_encanta|me_gusta|me_da_igual|solo_ocasional|no_me_gusta|nunca_sugerir
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
