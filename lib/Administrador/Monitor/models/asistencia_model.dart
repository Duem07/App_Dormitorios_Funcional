class Asistencia {
  final String matricula;
  final String nombreCompleto; 

  Asistencia({
    required this.matricula,
    required this.nombreCompleto,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      matricula: json['Matricula']?.toString() ?? 
                 json['matricula']?.toString() ?? 
                 json['MatriculaEstudiante']?.toString() ?? 
                 '',
      nombreCompleto: json['NombreCompleto']?.toString() ?? 
                      json['nombreCompleto']?.toString() ?? 
                      'Sin Nombre', 
    );
  }
}