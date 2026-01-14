import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/grafico_estadisticas.dart';

class EstadisticasMonitorScreen extends StatefulWidget {
  const EstadisticasMonitorScreen({super.key});

  @override
  State<EstadisticasMonitorScreen> createState() => _EstadisticasMonitorScreenState();
}

class _EstadisticasMonitorScreenState extends State<EstadisticasMonitorScreen> {
  final _limpiezaService = LimpiezaService();
  bool _isLoading = true;
  List<dynamic> _datosPublicados = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final resultado = await _limpiezaService.obtenerEstadisticas();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success'] == true) {
          // El Monitor también ve lo 'publicado' (igual que el estudiante)
          // El preceptor es el único que ve lo que está "En Curso"
          _datosPublicados = resultado['data']['publicadas'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas del Pasillo'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
               const SizedBox(height: 10),
               
               // Podemos poner un encabezado diferente para el monitor
               const Text(
                 "Desempeño General",
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const Text(
                 "Resultados visibles para los estudiantes actualmente.",
                 style: TextStyle(color: Colors.grey),
               ),
               const SizedBox(height: 20),

               GraficoPasillos(
                datos: _datosPublicados,
                titulo: "Ranking de Pasillos",
                subTitulo: "Comparativa del último ciclo cerrado.",
                esVacio: _datosPublicados.isEmpty,
              ),
            ],
          ),
    );
  }
}