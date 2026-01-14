import 'package:flutter/material.dart';

class GraficoPasillos extends StatelessWidget {
  final List<dynamic> datos;
  final String titulo;
  final String subTitulo;
  final bool esVacio;

  const GraficoPasillos({
    super.key,
    required this.datos,
    required this.titulo,
    required this.subTitulo,
    this.esVacio = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subTitulo, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 24),
            
            if (esVacio)
              Container(
                height: 100,
                alignment: Alignment.center,
                child: Text("Sin datos suficientes en este periodo", style: TextStyle(color: Colors.grey[400])),
              )
            else
              ...datos.map((dato) {
                final nombre = dato['Pasillo'] ?? 'Desconocido';
                final promedio = double.tryParse(dato['Promedio'].toString()) ?? 0.0;
                
                // Semáforo de colores
                Color colorBarra;
                if (promedio >= 90) colorBarra = Colors.green;
                else if (promedio >= 80) colorBarra = Colors.blue;
                else if (promedio >= 70) colorBarra = Colors.orange;
                else colorBarra = Colors.red;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(
                            "${promedio.toStringAsFixed(1)}%", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: colorBarra, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Animación de la barra
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: promedio / 100),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: Colors.grey[100],
                            valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}