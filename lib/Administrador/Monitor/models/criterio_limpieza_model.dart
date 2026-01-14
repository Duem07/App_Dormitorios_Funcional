class CriterioLimpieza {
  final int idCriterio;
  final String descripcion;
  int calificacion;

  CriterioLimpieza({
    required this.idCriterio,
    required this.descripcion,
    this.calificacion = 10,
  });

  factory CriterioLimpieza.fromJson(Map<String, dynamic> json) {
    return CriterioLimpieza(
      idCriterio: json['IdCriterio'],
      descripcion: json['Descripcion'] ?? 'Criterio desconocido',
    );
  }
}