class MonitorInfo {
  final String usuarioID; // Matricula
  final String nombreCompleto;

  MonitorInfo({
    required this.usuarioID,
    required this.nombreCompleto,
  });


  factory MonitorInfo.fromJson(Map<String, dynamic> json) {
    return MonitorInfo(
      // Usamos '??' para proveer un valor por defecto si el campo es nulo
      usuarioID: json['UsuarioID'] ?? 'N/A', 
      nombreCompleto: json['NombreCompleto'] ?? 'Nombre Desconocido',
    );
  }
}

