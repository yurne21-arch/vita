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
    this.quien,
    this.compartido = false,
    this.metodo,
    this.tarjeta,
  });

  final String id;
  final String tipo; // 'gasto' | 'ingreso'
  final double monto; // siempre positivo
  final String categoria;
  final String ambito; // 'personal' | 'casa'
  final DateTime fecha; // date (sin hora)
  final String? nota;
  final String? quien; // 'Yurby' | 'Juan' | 'Ambos'
  final bool compartido; // se reparte entre ambos
  final String? metodo; // 'efectivo' | 'tarjeta' | 'cuenta'
  final String? tarjeta; // medio de pago (texto libre)

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
        quien: m['quien'] as String?,
        compartido: (m['compartido'] as bool?) ?? false,
        metodo: m['metodo'] as String?,
        tarjeta: m['tarjeta'] as String?,
      );
}

/// Tarjeta de crédito.
class Tarjeta {
  const Tarjeta({
    required this.id,
    required this.nombre,
    required this.cupo,
    required this.saldoDeuda,
    required this.cuotaMes,
    this.titular,
    this.diaCierre,
    this.diaPago,
  });

  final String id;
  final String nombre;
  final String? titular;
  final double cupo;
  final double saldoDeuda;
  final double cuotaMes;
  final int? diaCierre;
  final int? diaPago;

  double get disponible => (cupo - saldoDeuda).clamp(0, cupo);
  double get usoFraccion => cupo <= 0 ? 0 : (saldoDeuda / cupo).clamp(0.0, 1.0);

  factory Tarjeta.fromMap(Map<String, dynamic> m) => Tarjeta(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        titular: m['titular'] as String?,
        cupo: (m['cupo'] as num?)?.toDouble() ?? 0,
        saldoDeuda: (m['saldo_deuda'] as num?)?.toDouble() ?? 0,
        cuotaMes: (m['cuota_mes'] as num?)?.toDouble() ?? 0,
        diaCierre: (m['dia_cierre'] as num?)?.toInt(),
        diaPago: (m['dia_pago'] as num?)?.toInt(),
      );
}

/// Crédito o deuda estructurada (hipoteca, crédito de consumo, etc.).
class Credito {
  const Credito({
    required this.id,
    required this.nombre,
    required this.cuotaMensual,
    required this.montoTotal,
    required this.saldada,
    this.fin,
    this.progreso,
  });

  final String id;
  final String nombre;
  final double cuotaMensual;
  final double montoTotal;
  final bool saldada;
  final String? fin; // etiqueta libre, ej. "Abr 2051"
  final int? progreso; // 0..100

  factory Credito.fromMap(Map<String, dynamic> m) => Credito(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        cuotaMensual: (m['cuota_mensual'] as num?)?.toDouble() ?? 0,
        montoTotal: (m['monto_total'] as num?)?.toDouble() ?? 0,
        saldada: m['saldada'] as bool? ?? false,
        fin: m['fin'] as String?,
        progreso: (m['progreso'] as num?)?.toInt(),
      );
}

/// Meta de ahorro (sueño con monto).
class Meta {
  const Meta({
    required this.id,
    required this.label,
    required this.metaMonto,
    required this.ahorrado,
    required this.cumplida,
    this.emoji,
  });

  final String id;
  final String label;
  final String? emoji;
  final double metaMonto;
  final double ahorrado;
  final bool cumplida;

  double get fraccion =>
      metaMonto <= 0 ? 0 : (ahorrado / metaMonto).clamp(0.0, 1.0);

  factory Meta.fromMap(Map<String, dynamic> m) => Meta(
        id: m['id'] as String,
        label: m['label'] as String,
        emoji: m['emoji'] as String?,
        metaMonto: (m['meta_monto'] as num?)?.toDouble() ?? 0,
        ahorrado: (m['ahorrado'] as num?)?.toDouble() ?? 0,
        cumplida: m['cumplida'] as bool? ?? false,
      );
}

/// Cuenta con saldo (débito, efectivo, RUT, etc.).
class Cuenta {
  const Cuenta({
    required this.id,
    required this.nombre,
    required this.saldo,
    this.titular,
  });

  final String id;
  final String nombre;
  final String? titular; // 'Yurby' | 'Juan' | 'Ambos'
  final double saldo;

  factory Cuenta.fromMap(Map<String, dynamic> m) => Cuenta(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        titular: m['titular'] as String?,
        saldo: (m['saldo'] as num?)?.toDouble() ?? 0,
      );
}

/// Un pago hecho a un crédito (una cuota).
class PagoCredito {
  const PagoCredito({
    required this.id,
    required this.monto,
    required this.fecha,
    this.nota,
  });

  final String id;
  final double monto;
  final DateTime fecha;
  final String? nota;

  factory PagoCredito.fromMap(Map<String, dynamic> m) => PagoCredito(
        id: m['id'] as String,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        nota: m['nota'] as String?,
      );
}

/// Resumen de los pagos de un crédito: cuántas cuotas y cuánto en total.
class ResumenCredito {
  const ResumenCredito({required this.cuotas, required this.totalPagado});
  final int cuotas;
  final double totalPagado;
  static const ResumenCredito vacio =
      ResumenCredito(cuotas: 0, totalPagado: 0);
}

/// Balance del reparto compartido (Tricount): cuánto puso cada quien de los
/// gastos marcados como compartidos, y quién le debe a quién para equilibrar.
class BalanceCompartido {
  const BalanceCompartido({
    required this.puestoPorYurby,
    required this.puestoPorJuan,
  });

  final double puestoPorYurby;
  final double puestoPorJuan;

  double get total => puestoPorYurby + puestoPorJuan;
  double get mitad => total / 2;

  /// Diferencia respecto a partes iguales. Positivo: a Yurby le deben.
  double get aFavorDeYurby => puestoPorYurby - mitad;

  bool get equilibrado => aFavorDeYurby.abs() < 1;
  bool get juanLeDebeAYurby => aFavorDeYurby > 0;
  double get montoAjuste => aFavorDeYurby.abs();
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
