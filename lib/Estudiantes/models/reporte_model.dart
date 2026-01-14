class Reporte {
  final int id;
  final DateTime? fecha;
  final String motivo;
  final String estado;
  final String reportadoPor;

  Reporte({
    required this.id,
    this.fecha,
    required this.motivo,
    required this.estado,
    required this.reportadoPor,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      fecha: json['FechaReporte'] != null ? DateTime.tryParse(json['FechaReporte']) : null,
      id: json['IdReporte'],
      motivo: json['Motivo'] ?? 'Sin motivo',
      estado: json['Estado'] ?? 'Desconocido',
      reportadoPor: json['ReportadoPorNombre'] ?? 'Sistema',
    );
  }
}