// Motor nutricional determinista de VITA (Dart puro, sin Flutter ni Supabase).
//
// Dada una biblioteca aprobada (alimentos → preparaciones → ensambles) y los
// perfiles con sus metas, genera la semana: menú por día, porciones por persona
// que CIERRAN dentro de tolerancia (§2.8 del cerebro), producciones base del
// domingo, mapa de refrigeración/congelación y lista de compras.
//
// Determinista: misma entrada → misma salida. No usa azar; la rotación es por
// índice. Las calorías son PROVISIONALES (dependen del perfil real).

import 'alimentacion.dart';

/// Biblioteca aprobada, con índices por id para resolver componentes.
class Biblioteca {
  Biblioteca({
    required this.alimentos,
    required this.preparaciones,
    required this.ensambles,
  })  : _alimentos = {for (final a in alimentos) a.id: a},
        _preparaciones = {for (final p in preparaciones) p.id: p};

  final List<Alimento> alimentos;
  final List<Preparacion> preparaciones;
  final List<Ensamble> ensambles;

  final Map<String, Alimento> _alimentos;
  final Map<String, Preparacion> _preparaciones;

  Alimento? alimento(String? id) => id == null ? null : _alimentos[id];
  Preparacion? preparacion(String? id) =>
      id == null ? null : _preparaciones[id];

  /// El alimento subyacente de un componente (directo, o vía su preparación).
  Alimento? alimentoDe(ComponenteEnsamble c) {
    if (c.foodId != null) return _alimentos[c.foodId];
    final prep = _preparaciones[c.preparationId];
    return alimento(prep?.foodId);
  }

  List<Ensamble> porMomento(String momento) =>
      ensambles.where((e) => e.aprobado && e.momento == momento).toList();
}

/// Una porción calculada de una comida, para una persona.
class PorcionCalculada {
  const PorcionCalculada({
    required this.persona,
    required this.gramos,
    required this.macros,
    this.ajuste,
  });

  final String persona;
  final Map<String, double> gramos; // componenteId → gramos (o ml/unidad)
  final Macros macros;
  final String? ajuste; // qué movió el motor para cerrar (auditoría)
}

/// Una comida planificada (un momento del día) con sus porciones por persona.
class ComidaPlan {
  const ComidaPlan({
    required this.momento,
    required this.ensamble,
    required this.porciones,
    this.alternativa,
  });

  final String momento;
  final Ensamble ensamble;
  final List<PorcionCalculada> porciones;
  final Ensamble? alternativa;

  PorcionCalculada? porcionDe(String persona) {
    for (final p in porciones) {
      if (p.persona == persona) return p;
    }
    return null;
  }
}

/// Un día del plan.
class DiaPlan {
  const DiaPlan({
    required this.fecha,
    required this.nombre,
    required this.comidas,
    required this.totales,
  });

  final DateTime fecha;
  final String nombre; // 'Lunes'…
  final List<ComidaPlan> comidas;
  final Map<String, Macros> totales; // persona → total del día
}

/// Una producción base del domingo (se cuece una vez).
class Produccion {
  const Produccion({
    required this.base,
    required this.cocidoG,
    required this.crudoG,
    required this.terminaciones,
  });

  final Preparacion base;
  final double cocidoG;
  final double crudoG;
  final List<String> terminaciones;
}

/// Asignación de conservación de una preparación (refri o congelador) con fechas.
class Conservacion {
  const Conservacion({
    required this.preparacion,
    required this.estado,
    required this.fechaPrep,
    required this.fechaMaxConsumo,
    this.fechaCongelar,
    this.fechaDescongelar,
  });

  final String preparacion;
  final String estado; // 'refri' | 'congelado'
  final DateTime fechaPrep;
  final DateTime fechaMaxConsumo;
  final DateTime? fechaCongelar;
  final DateTime? fechaDescongelar;
}

/// Un ítem de la lista de compras (cantidad cruda agregada de la semana).
class ItemCompra {
  const ItemCompra({
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
  });

  final String nombre;
  final String categoria;
  final double cantidad;
  final String unidad;
}

/// La lista de compras, dividida en compra principal y reposición de frescos.
class ListaCompras {
  const ListaCompras({required this.principal, required this.reposicion});
  final List<ItemCompra> principal;
  final List<ItemCompra> reposicion;
}

/// El plan completo de la semana.
class PlanSemana {
  const PlanSemana({
    required this.inicio,
    required this.dias,
    required this.producciones,
    required this.produccionesBase,
    required this.conservacion,
    required this.compras,
  });

  final DateTime inicio;
  final List<DiaPlan> dias;
  final List<Produccion> producciones;
  final int produccionesBase;
  final List<Conservacion> conservacion;
  final ListaCompras compras;

  DiaPlan? diaDe(DateTime fecha) {
    for (final d in dias) {
      if (d.fecha.year == fecha.year &&
          d.fecha.month == fecha.month &&
          d.fecha.day == fecha.day) {
        return d;
      }
    }
    return null;
  }
}

const _nombresDia = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo' //
];

// Porción por defecto según el rol del componente (gramos / ml).
const _porcionDefault = <String, double>{
  'proteina': 150,
  'base': 150,
  'verdura': 90,
  'fresco': 50,
  'aliño': 8,
  'lacteo': 200,
  'fruta': 120,
};

// Reparto orientativo de la energía del día. El almuerzo lleva el grueso y
// absorbe el cierre; la merienda es liviana (§ meriendas de la lista aprobada).
const _pesoMomento = <String, double>{
  'desayuno': 0.30,
  'almuerzo': 0.55,
  'merienda': 0.15,
  'finde': 0.55,
};

/// El motor. Sin estado; una llamada a [generar] produce el plan completo.
class MotorNutricional {
  const MotorNutricional();

  PlanSemana generar({
    required List<PerfilNutricional> perfiles,
    required Biblioteca biblioteca,
    required DateTime inicioSemana,
    int rotacion = 0,
  }) {
    final dias = <DiaPlan>[];
    // Para no repetir un plato dos días seguidos y respetar topes de proteína.
    final usadosAyer = <String>{};
    final vecesProteina = <String, int>{};

    for (var i = 0; i < 7; i++) {
      final fecha = inicioSemana.add(Duration(days: i));
      final finde = i >= 5;
      final momentos = ['desayuno', finde ? 'finde' : 'almuerzo', 'merienda'];
      final usadosHoy = <String>{};
      final comidas = <ComidaPlan>[];

      // 1) Elegir los ensambles del día (compartidos por ambas personas).
      final elegidos = <(String, Ensamble, Ensamble?)>[];
      for (final momento in momentos) {
        // El tope de proteína aplica al plato principal (almuerzo/finde), no a
        // desayunos o meriendas: cocinar pollo alcanza para varias comidas.
        final esPrincipal = momento == 'almuerzo' || momento == 'finde';
        final ensamble = _elegirEnsamble(
          biblioteca,
          momento,
          i + rotacion,
          usadosAyer,
          usadosHoy,
          esPrincipal ? vecesProteina : const {},
        );
        if (ensamble == null) continue;
        usadosHoy.add(ensamble.id);
        if (esPrincipal) {
          final prot = _proteinaPrincipal(biblioteca, ensamble);
          if (prot != null) {
            vecesProteina[prot] = (vecesProteina[prot] ?? 0) + 1;
          }
        }
        elegidos.add((momento, ensamble, _alternativaDe(biblioteca, ensamble)));
      }

      usadosAyer
        ..clear()
        ..addAll(usadosHoy);

      // 2) Calcular el día completo por persona y cerrarlo en tolerancia.
      final porPersona = <String, List<PorcionCalculada>>{};
      final totales = <String, Macros>{};
      for (final perfil in perfiles) {
        final meals = [
          for (final (momento, ensamble, _) in elegidos)
            _calcMeal(biblioteca, ensamble, momento, perfil),
        ];
        _cerrarDia(meals, perfil);
        totales[perfil.nombre] =
            meals.fold(Macros.cero, (s, m) => s + m.macros());
        porPersona[perfil.nombre] = [for (final m in meals) m.materializar()];
      }

      // 3) Agrupar por comida (todas las porciones de un mismo ensamble juntas).
      for (var j = 0; j < elegidos.length; j++) {
        final (momento, ensamble, alternativa) = elegidos[j];
        comidas.add(ComidaPlan(
          momento: momento,
          ensamble: ensamble,
          alternativa: alternativa,
          porciones: [
            for (final perfil in perfiles) porPersona[perfil.nombre]![j],
          ],
        ));
      }

      dias.add(DiaPlan(
        fecha: fecha,
        nombre: _nombresDia[i],
        comidas: comidas,
        totales: totales,
      ));
    }

    final producciones = _rollupProducciones(biblioteca, dias);
    final conservacion = _mapaConservacion(inicioSemana, producciones);
    final compras = _listaCompras(biblioteca, dias);

    return PlanSemana(
      inicio: inicioSemana,
      dias: dias,
      producciones: producciones,
      produccionesBase: producciones.length,
      conservacion: conservacion,
      compras: compras,
    );
  }

  // ── Selección de menú ──────────────────────────────────────────

  Ensamble? _elegirEnsamble(
    Biblioteca b,
    String momento,
    int giro,
    Set<String> usadosAyer,
    Set<String> usadosHoy,
    Map<String, int> vecesProteina,
  ) {
    // Las alternativas (plan B) no se agendan solas: se excluyen de la rotación.
    final candidatos = b
        .porMomento(momento)
        .where((e) => e.alternativaDe == null)
        .toList()
      ..sort((x, y) => _pesoFrecuencia(x.frecuencia)
          .compareTo(_pesoFrecuencia(y.frecuencia)));
    if (candidatos.isEmpty) return null;

    // Recorre desde un punto que rota por día; toma el primero admisible.
    final n = candidatos.length;
    for (var k = 0; k < n; k++) {
      final e = candidatos[(giro + k) % n];
      if (e.alternativaDe != null) continue; // las alternativas no se agendan
      if (usadosAyer.contains(e.id) || usadosHoy.contains(e.id)) continue;
      final prot = _proteinaPrincipal(b, e);
      if (prot != null && (vecesProteina[prot] ?? 0) >= 4) continue; // tope
      return e;
    }
    // Si todo quedó filtrado, cae al de la rotación (evita día vacío).
    return candidatos[giro % n];
  }

  int _pesoFrecuencia(String f) {
    switch (f) {
      case Frecuencias.favoritaFrecuente:
        return 0;
      case Frecuencias.frecuente:
        return 1;
      case Frecuencias.ocasional:
        return 2;
      case Frecuencias.soloFinde:
        return 3;
      default:
        return 4;
    }
  }

  String? _proteinaPrincipal(Biblioteca b, Ensamble e) {
    for (final c in e.componentes) {
      if (c.rol == 'proteina') {
        final a = b.alimentoDe(c);
        if (a != null) return a.nombre;
      }
    }
    return null;
  }

  Ensamble? _alternativaDe(Biblioteca b, Ensamble e) {
    for (final x in b.ensambles) {
      if (x.alternativaDe == e.id) return x;
    }
    return null;
  }

  // ── Cálculo de porciones que CIERRAN en tolerancia ─────────────

  /// Calcula una comida apuntando a su cuota del día (sin cierre todavía).
  _MealPortion _calcMeal(
    Biblioteca b,
    Ensamble e,
    String momento,
    PerfilNutricional perfil,
  ) {
    final kcalDia = perfil.kcalObjetivo ?? 1800;
    final protDia = perfil.protObjetivoG ?? (kcalDia * 0.3 / 4);
    final peso = _pesoMomento[momento] ?? 0.33;

    final comps = <_Comp>[];
    for (final c in e.componentes) {
      final a = b.alimentoDe(c);
      if (a == null) continue;
      comps.add(_Comp(c, a, _gramosDefault(c.rol, a)));
    }
    final meal = _MealPortion(perfil.nombre, comps);
    if (comps.isEmpty) return meal;

    // 1) Proteína del momento → su cuota de la meta proteica del día.
    final prot = meal.proteico;
    if (prot != null && prot.alimento.macros100.prot > 0) {
      prot.gramos = _limitar(
          protDia * peso / (prot.alimento.macros100.prot / 100), 40, 400);
    }
    // 2) Carbohidrato → completa las kcal del momento (el resto).
    final carbo = meal.carbo;
    if (carbo != null && carbo.alimento.macros100.kcal > 0) {
      final otras = comps
          .where((c) => !identical(c, carbo))
          .fold<double>(0, (s, c) => s + c.alimento.macrosPara(c.gramos).kcal);
      carbo.gramos = _limitar(
          (kcalDia * peso - otras) / (carbo.alimento.macros100.kcal / 100),
          20,
          600);
    }
    return meal;
  }

  /// Ajusta el almuerzo para que el DÍA cierre: proteína ≥ meta y kcal en ±tol.
  /// No inventa comidas; solo mueve porciones ya presentes.
  void _cerrarDia(List<_MealPortion> meals, PerfilNutricional perfil) {
    if (meals.isEmpty) return;
    // El almuerzo (mayor peso) absorbe el cierre; si no, la comida más grande.
    final ancla =
        meals.reduce((a, z) => z.macros().kcal > a.macros().kcal ? z : a);
    final protMin = perfil.protObjetivoG;
    final metaKcal = perfil.kcalObjetivo;

    // a) Cerrar proteína: subir el proteico del ancla hasta la meta diaria.
    if (protMin != null && ancla.proteico != null) {
      final prot = ancla.proteico!;
      final por100 = prot.alimento.macros100.prot;
      if (por100 > 0) {
        var faltan = protMin - _sumaProt(meals);
        if (faltan > 0) {
          prot.gramos =
              _limitar(prot.gramos + faltan / (por100 / 100), 40, 400);
        }
      }
    }

    // b) Cerrar calorías con el carbohidrato del ancla.
    if (metaKcal != null && ancla.carbo != null) {
      final carbo = ancla.carbo!;
      final por100 = carbo.alimento.macros100.kcal;
      if (por100 > 0) {
        final tol = metaKcal * perfil.kcalToleranciaPct / 100;
        final delta = metaKcal - _sumaKcal(meals); // + faltan, − sobran
        if (delta.abs() > tol) {
          carbo.gramos =
              _limitar(carbo.gramos + delta / (por100 / 100), 20, 600);
        }
      }
    }
  }

  double _sumaKcal(List<_MealPortion> m) =>
      m.fold(0, (s, x) => s + x.macros().kcal);
  double _sumaProt(List<_MealPortion> m) =>
      m.fold(0, (s, x) => s + x.macros().prot);

  double _limitar(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);

  /// Porción por defecto de un componente fijo (los proteicos y carbo se
  /// recalculan). El queso/quesillo (lácteo sólido) va como topping, no 200 g.
  double _gramosDefault(String rol, Alimento a) {
    if (rol == 'lacteo' && a.unidad == 'g') return 30;
    return _porcionDefault[rol] ?? 100;
  }

  // ── Producciones base (roll-up del domingo) ────────────────────

  List<Produccion> _rollupProducciones(Biblioteca b, List<DiaPlan> dias) {
    // baseId → (cocidoG acumulado, terminaciones vistas)
    final cocido = <String, double>{};
    final terms = <String, Set<String>>{};

    for (var i = 0; i < dias.length && i < 5; i++) {
      // Solo Lun–Vie: el fin de semana se cocina fresco.
      for (final comida in dias[i].comidas) {
        for (final comp in comida.ensamble.componentes) {
          final prep = b.preparacion(comp.preparationId);
          if (prep == null || !prep.mealPrep) continue;
          final baseId = prep.esBase ? prep.id : (prep.derivaDe ?? prep.id);
          var g = 0.0;
          for (final por in comida.porciones) {
            g += por.gramos[comp.id] ?? 0;
          }
          cocido[baseId] = (cocido[baseId] ?? 0) + g;
          (terms[baseId] ??= <String>{}).add(prep.nombre);
        }
      }
    }

    final out = <Produccion>[];
    cocido.forEach((baseId, g) {
      final base = b.preparacion(baseId);
      if (base == null) return;
      final food = b.alimento(base.foodId);
      final rinde = food?.rindeCocidoPct;
      final crudo = (rinde != null && rinde > 0) ? g / (rinde / 100) : g;
      out.add(Produccion(
        base: base,
        cocidoG: g,
        crudoG: crudo,
        terminaciones: (terms[baseId] ?? {}).toList()..sort(),
      ));
    });
    out.sort((a, z) => z.cocidoG.compareTo(a.cocidoG));
    return out;
  }

  // ── Mapa de refrigeración y congelación ────────────────────────

  List<Conservacion> _mapaConservacion(
      DateTime inicio, List<Produccion> producciones) {
    final out = <Conservacion>[];
    for (final p in producciones) {
      // Primeros días en refri (Lun–Mié); a partir del jueves, congelador.
      out.add(Conservacion(
        preparacion: p.base.nombre,
        estado: 'refri',
        fechaPrep: inicio,
        fechaMaxConsumo: inicio.add(const Duration(days: 3)), // ~3–4 días
      ));
      if (p.base.congelable) {
        out.add(Conservacion(
          preparacion: p.base.nombre,
          estado: 'congelado',
          fechaPrep: inicio,
          fechaCongelar: inicio,
          fechaDescongelar: inicio.add(const Duration(days: 3)),
          fechaMaxConsumo: inicio.add(const Duration(days: 45)),
        ));
      }
    }
    return out;
  }

  // ── Lista de compras (cantidades crudas agregadas) ─────────────

  ListaCompras _listaCompras(Biblioteca b, List<DiaPlan> dias) {
    final acum = <String, double>{}; // alimentoId → gramos crudos
    final cat = <String, String>{};
    final uni = <String, String>{};
    final nom = <String, String>{};

    for (final dia in dias) {
      for (final comida in dia.comidas) {
        for (final comp in comida.ensamble.componentes) {
          final a = b.alimentoDe(comp);
          if (a == null) continue;
          var g = 0.0;
          for (final por in comida.porciones) {
            g += por.gramos[comp.id] ?? 0;
          }
          if (g <= 0) continue;
          final crudo = (a.rindeCocidoPct != null && a.rindeCocidoPct! > 0)
              ? g / (a.rindeCocidoPct! / 100)
              : g;
          acum[a.id] = (acum[a.id] ?? 0) + crudo;
          cat[a.id] = a.categoria;
          uni[a.id] = a.unidad;
          nom[a.id] = a.nombre;
        }
      }
    }

    const frescos = {'verdura', 'fresco', 'fruta', 'lacteo'};
    final principal = <ItemCompra>[];
    final reposicion = <ItemCompra>[];
    acum.forEach((id, g) {
      final item = ItemCompra(
        nombre: nom[id]!,
        categoria: cat[id]!,
        cantidad: g,
        unidad: uni[id]!,
      );
      (frescos.contains(cat[id]) ? reposicion : principal).add(item);
    });
    int porNombre(ItemCompra a, ItemCompra z) => a.nombre.compareTo(z.nombre);
    principal.sort(porNombre);
    reposicion.sort(porNombre);
    return ListaCompras(principal: principal, reposicion: reposicion);
  }
}

/// Componente resuelto con sus gramos mutables durante el cálculo.
class _Comp {
  _Comp(this.componente, this.alimento, this.gramos) : gramosBase = gramos;
  final ComponenteEnsamble componente;
  final Alimento alimento;
  final double gramosBase; // porción por defecto (para la nota de ajuste)
  double gramos;
}

/// Una comida en cálculo: sus componentes mutables y el análisis proteico/carbo.
class _MealPortion {
  _MealPortion(this.persona, this.comps) {
    for (final c in comps) {
      if (c.alimento.macros100.prot > 0 &&
          (proteico == null ||
              c.alimento.macros100.prot > proteico!.alimento.macros100.prot)) {
        proteico = c;
      }
    }
    for (final c in comps) {
      if (identical(c, proteico)) continue;
      if (c.alimento.macros100.carb > 0 &&
          (carbo == null ||
              c.alimento.macros100.carb > carbo!.alimento.macros100.carb)) {
        carbo = c;
      }
    }
  }

  final String persona;
  final List<_Comp> comps;
  _Comp? proteico;
  _Comp? carbo;

  Macros macros() =>
      comps.fold(Macros.cero, (s, c) => s + c.alimento.macrosPara(c.gramos));

  PorcionCalculada materializar() {
    final cambios = <String>[];
    for (final c in [proteico, carbo]) {
      if (c == null) continue;
      if ((c.gramos - c.gramosBase).abs() >= 5) {
        cambios.add(
            '${c.alimento.nombre} ${c.gramosBase.round()}→${c.gramos.round()} ${c.alimento.unidad}');
      }
    }
    return PorcionCalculada(
      persona: persona,
      gramos: {for (final c in comps) c.componente.id: c.gramos},
      macros: macros(),
      ajuste: cambios.isEmpty ? null : cambios.join(', '),
    );
  }
}
