import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/grafico_estadisticas.dart'; // Asegúrate de importar el widget que creamos

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final _limpiezaService = LimpiezaService();
  bool _isLoading = true;
  List<dynamic> _datosPublicados = [];
  
  // Variable opcional por si quisieras mostrar la fecha del corte
  // String _fechaCorte = ""; 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // 1. Llamamos al servicio
    final resultado = await _limpiezaService.obtenerEstadisticas();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success'] == true) {
          // 2. IMPORTANTE: Los estudiantes ven 'publicadas' (el ciclo ya cerrado)
          // No ven 'enCurso' para evitar chismes o reclamos antes de tiempo.
          _datosPublicados = resultado['data']['publicadas'] ?? [];
        }
      });
    }
  }

  // Función extra para encontrar al ganador y mostrarlo destacado
  String _obtenerGanador() {
    if (_datosPublicados.isEmpty) return "Nadie";
    // Buscamos el que tenga mayor promedio
    var ganador = _datosPublicados.reduce((curr, next) {
      double p1 = double.tryParse(curr['Promedio'].toString()) ?? 0;
      double p2 = double.tryParse(next['Promedio'].toString()) ?? 0;
      return p1 > p2 ? curr : next;
    });
    return ganador['Pasillo'] ?? "Nadie";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados Oficiales'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _cargarDatos, // Permite deslizar para actualizar
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                 // --- Tarjeta Informativa Superior ---
                 Container(
                   padding: const EdgeInsets.all(16),
                   margin: const EdgeInsets.only(bottom: 20),
                   decoration: BoxDecoration(
                     color: Colors.green.shade50,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.green.shade200),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.green.withOpacity(0.1),
                         blurRadius: 10,
                         offset: const Offset(0, 4),
                       )
                     ]
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.emoji_events, color: Colors.green.shade700, size: 40),
                       const SizedBox(width: 15),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               "Pasillo Ganador",
                               style: TextStyle(
                                 color: Colors.green.shade900,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14
                               ),
                             ),
                             Text(
                               _obtenerGanador(),
                               style: TextStyle(
                                 color: Colors.green.shade800,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 22
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),

                 const SizedBox(height: 10),

                 // --- Gráfica de Barras (El Widget Reutilizable) ---
                 GraficoPasillos(
                  datos: _datosPublicados,
                  titulo: "Calificaciones del Periodo",
                  subTitulo: "Promedios finales del último corte realizado por Preceptoría.",
                  esVacio: _datosPublicados.isEmpty,
                ),
                
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Nota: Los sábados no se toman en cuenta para el promedio.",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                )
              ],
            ),
          ),
    );
  }
}