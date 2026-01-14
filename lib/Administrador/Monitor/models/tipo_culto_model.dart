class TipoCulto {
  final int idTipoCulto;
  final String nombre;

  TipoCulto({required this.idTipoCulto, required this.nombre});

  factory TipoCulto.fromJson(Map<String, dynamic> json) {
    return TipoCulto(
      idTipoCulto: json['IdTipoCulto'],
      nombre: json['Nombre'] ?? 'Culto desconocido',
    );
  }
}