import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/dormitorio_service.dart';

class VerOcupacionScreen extends StatefulWidget {
  const VerOcupacionScreen({super.key});

  @override
  State<VerOcupacionScreen> createState() => _VerOcupacionScreenState();
}

class _VerOcupacionScreenState extends State<VerOcupacionScreen> {
  final DormitorioService _service = DormitorioService();
  bool _isLoading = true;
  
  // Estructura: Mapa donde la llave es el "Pasillo" y el valor es una lista de cuartos
  Map<String, List<Map<String, dynamic>>> _datosAgrupados = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final rawData = await _service.getOcupacion();
    
    // --- LÓGICA DE AGRUPACIÓN (Transformar lista plana a jerarquía) ---
    Map<String, Map<int, Map<String, dynamic>>> tempMap = {};

    for (var item in rawData) {
      String pasillo = item['NombrePasillo'] ?? 'Sin Pasillo';
      int idCuarto = item['IdCuarto'];
      
      // Inicializar Pasillo si no existe
      if (!tempMap.containsKey(pasillo)) {
        tempMap[pasillo] = {};
      }

      // Inicializar Cuarto si no existe en ese pasillo
      if (!tempMap[pasillo]!.containsKey(idCuarto)) {
        tempMap[pasillo]![idCuarto] = {
          'NumeroCuarto': item['NumeroCuarto'],
          'Capacidad': item['Capacidad'],
          'Estudiantes': <String>[]
        };
      }

      // Agregar estudiante si existe en esa fila
      if (item['Estudiante'] != null) {
        tempMap[pasillo]![idCuarto]!['Estudiantes'].add(item['Estudiante']);
      }
    }

    // Convertir a estructura final para la UI
    Map<String, List<Map<String, dynamic>>> finalMap = {};
    tempMap.forEach((pasillo, cuartosMap) {
      finalMap[pasillo] = cuartosMap.values.toList();
    });

    if (mounted) {
      setState(() {
        _datosAgrupados = finalMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ocupación de Cuartos')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: _datosAgrupados.entries.map((entry) {
              return _buildPasilloSection(entry.key, entry.value);
            }).toList(),
          ),
    );
  }

  Widget _buildPasilloSection(String nombrePasillo, List<Map<String, dynamic>> cuartos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Pasillo $nombrePasillo',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
        ),
        // Grid de Cuartos
        GridView.builder(
          shrinkWrap: true, // Importante para que funcione dentro de ListView
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columnas
            childAspectRatio: 0.8, // Altura de las tarjetas
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: cuartos.length,
          itemBuilder: (context, index) {
            return _buildCuartoCard(cuartos[index]);
          },
        ),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }

  Widget _buildCuartoCard(Map<String, dynamic> cuarto) {
    final estudiantes = cuarto['Estudiantes'] as List;
    final capacidad = cuarto['Capacidad'];
    final ocupados = estudiantes.length;
    final isLleno = ocupados >= capacidad;

    return Card(
      elevation: 3,
      // CORRECCIÓN AQUÍ: El 'side' va DENTRO del RoundedRectangleBorder
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLleno ? Colors.red.shade200 : Colors.green.shade200, 
          width: 2
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          // ... resto de tu código igual (children, Row, Divider, etc.) ...
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuarto ${cuarto['NumeroCuarto']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLleno ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    '$ocupados / $capacidad',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const Divider(),
            // Lista de nombres
            Expanded(
              child: estudiantes.isEmpty 
              ? Center(child: Text('Vacío', style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  itemCount: estudiantes.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              estudiantes[i], 
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            )
          ],
        ),
      ),
    );
  }
}