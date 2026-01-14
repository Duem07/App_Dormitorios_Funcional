class NivelAmonestacion {
  final int idNivel;
  final String nombre;

  NivelAmonestacion({required this.idNivel, required this.nombre});

  factory NivelAmonestacion.fromJson(Map<String, dynamic> json) {
    return NivelAmonestacion(
      idNivel: json['IdNivel'] ?? 0,
      nombre: json['Nombre'] ?? 'Desconocido',
    );
  }
}
