/// Entidades de dominio de Finanzas (Dart puro, sin Flutter ni Supabase).

/// Un movimiento: gasto o ingreso.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.ambito,
    required this.fecha,
    this.nota,
  });

  final String id;
  final String tipo; // 'gasto' | 'ingreso'
  final double monto; // siempre positivo
  final String categoria;
  final String ambito; // 'personal' | 'casa'
  final DateTime fecha; // date (sin hora)
  final String? nota;

  bool get esGasto => tipo == 'gasto';
  bool get esIngreso => tipo == 'ingreso';

  /// Aporte al balance: los gastos restan, los ingresos suman.
  double get signo => esGasto ? -monto : monto;

  factory Movimiento.fromMap(Map<String, dynamic> m) => Movimiento(
        id: m['id'] as String,
        tipo: m['tipo'] as String,
        monto: (m['monto'] as num).toDouble(),
        categoria: m['categoria'] as String,
        ambito: (m['ambito'] as String?) ?? 'personal',
        fecha: DateTime.parse(m['fecha'] as String),
        nota: m['nota'] as String?,
      );
}

/// Presupuesto mensual para una categoría.
class Presupuesto {
  const Presupuesto({
    required this.id,
    required this.categoria,
    required this.montoMensual,
  });

  final String id;
  final String categoria;
  final double montoMensual;

  factory Presupuesto.fromMap(Map<String, dynamic> m) => Presupuesto(
        id: m['id'] as String,
        categoria: m['categoria'] as String,
        montoMensual: (m['monto_mensual'] as num).toDouble(),
      );
}

/// Una deuda: yo debo o me deben.
class Deuda {
  const Deuda({
    required this.id,
    required this.direccion,
    required this.persona,
    required this.monto,
    required this.saldada,
    required this.fecha,
    this.descripcion,
  });

  final String id;
  final String direccion; // 'debo' | 'me_deben'
  final String persona;
  final double monto;
  final bool saldada;
  final DateTime fecha;
  final String? descripcion;

  bool get yoDebo => direccion == 'debo';

  factory Deuda.fromMap(Map<String, dynamic> m) => Deuda(
        id: m['id'] as String,
        direccion: m['direccion'] as String,
        persona: m['persona'] as String,
        monto: (m['monto'] as num).toDouble(),
        saldada: m['saldada'] as bool,
        fecha: DateTime.parse(m['fecha'] as String),
        descripcion: m['descripcion'] as String?,
      );
}

/// Resumen del mes en curso, ya calculado.
class ResumenMes {
  const ResumenMes({
    required this.gastos,
    required this.ingresos,
    required this.porCategoria,
  });

  final double gastos; // total gastado este mes
  final double ingresos; // total ingresado este mes
  final Map<String, double> porCategoria; // gasto por categoría

  double get balance => ingresos - gastos;

  static const ResumenMes vacio =
      ResumenMes(gastos: 0, ingresos: 0, porCategoria: {});
}

/// Categorías sugeridas (no es un enum rígido: la usuaria puede escribir otra).
const List<String> kCategoriasGasto = [
  'Comida',
  'Casa',
  'Transporte',
  'Salud',
  'Servicios',
  'Ocio',
  'Ropa',
  'Educación',
  'Otros',
];

const List<String> kCategoriasIngreso = [
  'Sueldo',
  'Extra',
  'Regalo',
  'Otros',
];
