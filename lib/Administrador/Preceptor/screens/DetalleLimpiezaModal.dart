import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:intl/intl.dart';

class DetalleLimpiezaModal extends StatelessWidget {
  final int idCuarto;
  final String numeroCuarto;

  const DetalleLimpiezaModal({
    super.key, 
    required this.idCuarto, 
    required this.numeroCuarto
  });

  @override
  Widget build(BuildContext context) {
    final LimpiezaService limpiezaService = LimpiezaService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Detalle Cuarto $numeroCuarto', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const Divider(),
          
          // Cuerpo
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: limpiezaService.obtenerDetalleLimpieza(idCuarto),
              builder: (context, snapshot) {
                // 1. ESTADO DE CARGA
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. MANEJO DE ERRORES REAL (Esto es lo nuevo)
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          const Text('Ocurrió un error:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                }

                // 3. DATOS VACÍOS O NULOS
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 40, color: Colors.grey),
                        Text('No se encontraron detalles para este cuarto.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 4. PINTAR DATOS (Si todo salió bien)
                try {
                  final data = snapshot.data!;
                  final detalles = data['Detalle'] as List<dynamic>;
                  
                  // Manejo seguro de fecha
                  String fechaTexto = 'Fecha desconocida';
                  if (data['Fecha'] != null) {
                    try {
                      final fecha = DateTime.parse(data['Fecha'].toString());
                      fechaTexto = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
                    } catch (e) {
                      fechaTexto = data['Fecha'].toString();
                    }
                  }

                  return ListView(
                    children: [
                      _infoRow(Icons.calendar_today, 'Fecha', fechaTexto),
                      _infoRow(Icons.person, 'Evaluador', data['EvaluadoPor'] ?? 'Monitor no encontrado'),
                      const SizedBox(height: 20),
                      
                      const Text('🌞 Evaluación Matutina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      // Verificar que 'detalles' no sea null
                      if (detalles.isEmpty) const Text('Sin detalles matutinos', style: TextStyle(fontStyle: FontStyle.italic)),
                      ...detalles.map((d) => _itemCalificacion(d['Criterio'] ?? 'Criterio', d['Calificacion'] ?? 0)),

                      const Divider(height: 30),

                      const Text('🌙 Evaluación Nocturna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      _itemCalificacion('Orden General', data['OrdenGeneral'] ?? 0),
                      _itemCalificacion('Disciplina', data['Disciplina'] ?? 0),

                      const Divider(height: 30),

                      if (data['Observaciones'] != null && data['Observaciones'].toString().isNotEmpty) ...[
                        const Text('💬 Observaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(data['Observaciones'], style: const TextStyle(fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('CALIFICACIÓN FINAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${data['TotalFinal'] ?? 0}/100', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  );
                } catch (e) {
                   return Center(child: Text("Error al procesar datos: $e"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _itemCalificacion(String concepto, int puntaje) {
    Color colorPuntaje = puntaje == 10 ? Colors.green : (puntaje >= 7 ? Colors.orange : Colors.red);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(concepto, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: colorPuntaje.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(puntaje.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: colorPuntaje)),
          ),
        ],
      ),
    );
  }
}