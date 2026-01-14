class LimpiezaReporte {
  final DateTime fecha;
  final String evaluadoPor;
  final int numeroCuarto;
  final List<DetalleLimpieza> detalle;
  final int subtotal;
  final int ordenGeneral;
  final int disciplina;
  final int totalFinal;

  LimpiezaReporte({
    required this.fecha,
    required this.evaluadoPor,
    required this.numeroCuarto,
    required this.detalle,
    required this.subtotal,
    required this.ordenGeneral,
    required this.disciplina,
    required this.totalFinal,
  });

  factory LimpiezaReporte.fromJson(Map<String, dynamic> json) {
    var detalleList = (json['Detalle'] as List)
        .map((item) => DetalleLimpieza.fromJson(item))
        .toList();

    return LimpiezaReporte(
      fecha: DateTime.parse(json['Fecha']),
      evaluadoPor: json['EvaluadoPor'] ?? 'N/A',
      numeroCuarto: json['NumeroCuarto'] ?? 0,
      detalle: detalleList,
      subtotal: json['Subtotal'] ?? 0,
      ordenGeneral: json['OrdenGeneral'] ?? 0,
      disciplina: json['Disciplina'] ?? 0,
      totalFinal: json['TotalFinal'] ?? 0,
    );
  }
}

class DetalleLimpieza {
  final String criterio;
  final int calificacion;

  DetalleLimpieza({
    required this.criterio,
    required this.calificacion,
  });

  factory DetalleLimpieza.fromJson(Map<String, dynamic> json) {
    return DetalleLimpieza(
      criterio: json['Criterio'] ?? '',
      calificacion: json['Calificacion'] ?? 0,
    );
  }
}