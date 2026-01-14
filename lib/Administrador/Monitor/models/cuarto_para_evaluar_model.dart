class CuartoParaEvaluar {
  final int idCuarto;
  final int numeroCuarto;
  final int? ultimaCalificacion; 
  final int idPasillo; 

  CuartoParaEvaluar({
    required this.idCuarto,
    required this.numeroCuarto,
    this.ultimaCalificacion,
    required this.idPasillo,
  });

  factory CuartoParaEvaluar.fromJson(Map<String, dynamic> json) {
    return CuartoParaEvaluar(
      idCuarto: json['IdCuarto'],
      numeroCuarto: json['NumeroCuarto'] ?? 0,
      ultimaCalificacion: json['UltimaCalificacion'],
      idPasillo: json['IdPasillo'] ?? 0,
    );
  }
}

