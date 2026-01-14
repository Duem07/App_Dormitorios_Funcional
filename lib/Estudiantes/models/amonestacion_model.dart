class Amonestacion {
  final int id; 
  final DateTime fecha;
  final String razon;
  final String severidad;
  final String preceptor;

  Amonestacion({
    required this.id,
    required this.fecha,
    required this.razon,
    required this.severidad,
    required this.preceptor,
  });

  factory Amonestacion.fromJson(Map<String, dynamic> json) {
    return Amonestacion(
      id: json['IdAmonestacion'],
      fecha: DateTime.parse(json['Fecha']),
      razon: json['Motivo'],
      severidad: json['Nivel'],
      preceptor: json['Preceptor'],
    );
  }
}