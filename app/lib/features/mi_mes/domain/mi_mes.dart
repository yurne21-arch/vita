/// Dominio de "Mi Mes": el balance mensual de la vida completa.
///
/// El balance es un ESPEJO (hechos del mes, sin juicio) + la REFLEXIÓN que la
/// usuaria escribe. Nada de puntajes, rachas ni marcadores "x de y": los datos
/// se muestran; el "bien/mal" lo pone ella (MASTER §2, §3).
library;

/// Balance completo de un mes: un resumen por área.
class BalanceMes {
  const BalanceMes({
    required this.mes,
    required this.proyectos,
    required this.salud,
    required this.habitos,
    required this.finanzas,
    required this.agenda,
  });

  final DateTime mes; // primer día del mes
  final ResumenProyectosMes proyectos;
  final ResumenSaludMes salud;
  final List<HabitoMes> habitos;
  final ResumenFinanzasMes finanzas;
  final ResumenAgendaMes agenda;

  /// El mes no tiene absolutamente nada registrado.
  bool get vacio =>
      proyectos.vacio &&
      salud.vacio &&
      habitos.isEmpty &&
      finanzas.vacio &&
      agenda.vacio;
}

// ───────────────── Proyectos / trabajo ─────────────────

class ResumenProyectosMes {
  const ResumenProyectosMes({
    required this.pasosCompletados,
    required this.hitosLogrados,
    required this.pendientes,
    required this.avances,
  });

  final int pasosCompletados;
  final int hitosLogrados;
  final int pendientes; // pasos aún por hacer en proyectos activos
  final List<String> avances; // lo que se avanzó (para listar)

  bool get vacio =>
      pasosCompletados == 0 &&
      hitosLogrados == 0 &&
      pendientes == 0 &&
      avances.isEmpty;

  static const vacia = ResumenProyectosMes(
      pasosCompletados: 0, hitosLogrados: 0, pendientes: 0, avances: []);
}

// ───────────────── Salud ─────────────────

class ResumenSaludMes {
  const ResumenSaludMes({
    required this.diasRegistrados,
    this.energiaProm,
    this.animoProm,
    this.suenoHorasProm,
    this.pesoInicio,
    this.pesoFin,
  });

  final int diasRegistrados; // días con algún registro de energía/ánimo/sueño
  final double? energiaProm; // 1–5
  final double? animoProm; // 1–5
  final double? suenoHorasProm; // horas
  final double? pesoInicio; // primer peso del mes
  final double? pesoFin; // último peso del mes

  double? get pesoDelta =>
      (pesoInicio != null && pesoFin != null) ? pesoFin! - pesoInicio! : null;

  bool get vacio =>
      diasRegistrados == 0 &&
      energiaProm == null &&
      animoProm == null &&
      suenoHorasProm == null &&
      pesoFin == null;

  static const vacia = ResumenSaludMes(diasRegistrados: 0);
}

// ───────────────── Hábitos ─────────────────

class HabitoMes {
  const HabitoMes({
    required this.nombre,
    required this.diasCumplidos,
    this.emoji,
  });

  final String nombre;
  final int diasCumplidos;
  final String? emoji;
}

// ───────────────── Finanzas ─────────────────

class ResumenFinanzasMes {
  const ResumenFinanzasMes({
    required this.ingresos,
    required this.gastos,
    required this.cerrado,
    required this.porCategoria,
  });

  final double ingresos;
  final double gastos;
  final bool cerrado; // ¿ya cerró el mes en Finanzas?
  final Map<String, double> porCategoria;

  double get balance => ingresos - gastos;

  /// Categoría donde más gastó (nombre, monto), o null si no hubo gastos.
  MapEntry<String, double>? get mayorGasto {
    if (porCategoria.isEmpty) return null;
    return porCategoria.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  bool get vacio => ingresos == 0 && gastos == 0;

  static const vacia =
      ResumenFinanzasMes(ingresos: 0, gastos: 0, cerrado: false, porCategoria: {});
}

// ───────────────── Agenda ─────────────────

class ResumenAgendaMes {
  const ResumenAgendaMes({required this.realizados, required this.total});

  final int realizados;
  final int total;

  bool get vacio => total == 0;

  static const vacia = ResumenAgendaMes(realizados: 0, total: 0);
}

// ───────────────── Reflexión (lo que ella escribe) ─────────────────

class ReflexionMes {
  const ReflexionMes({
    required this.anno,
    required this.mes,
    this.salioBien,
    this.aMejorar,
    this.foco,
  });

  final int anno;
  final int mes;
  final String? salioBien;
  final String? aMejorar;
  final String? foco;

  bool get vacia =>
      (salioBien == null || salioBien!.trim().isEmpty) &&
      (aMejorar == null || aMejorar!.trim().isEmpty) &&
      (foco == null || foco!.trim().isEmpty);

  factory ReflexionMes.fromMap(Map<String, dynamic> m) => ReflexionMes(
        anno: (m['anno'] as num).toInt(),
        mes: (m['mes'] as num).toInt(),
        salioBien: m['salio_bien'] as String?,
        aMejorar: m['a_mejorar'] as String?,
        foco: m['foco'] as String?,
      );
}
