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
  
  List<dynamic> _datosGrafica = [];
  List<dynamic> _datosMensuales = [];
  List<dynamic> _listaSemestres = [];
  String? _semestreSeleccionadoId;
  String _tituloSemestre = "";

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    final semestres = await _limpiezaService.obtenerSemestres();
    if (mounted) {
      setState(() {
        _listaSemestres = semestres;
        if (_semestreSeleccionadoId == null && semestres.isNotEmpty) {
           final activo = semestres.firstWhere((s) => s['Activo'] == true, orElse: () => semestres.first);
           _semestreSeleccionadoId = activo['IdSemestre'].toString();
        }
      });
      _cargarEstadisticas();
    }
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    final resultado = await _limpiezaService.obtenerEstadisticas(idSemestre: _semestreSeleccionadoId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success'] == true) {
          _datosGrafica = resultado['data']['grafica'] ?? [];
          _datosMensuales = resultado['data']['mensual'] ?? [];
          _tituloSemestre = resultado['data']['titulo'] ?? "";
        }
      });
    }
  }

  Map<String, List<dynamic>> _agruparPorMes() {
    Map<String, List<dynamic>> grupos = {};
    for (var dato in _datosMensuales) {
      String mes = dato['MesNombre'] ?? 'Desconocido';
      if (!grupos.containsKey(mes)) grupos[mes] = [];
      grupos[mes]!.add(dato);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas del Pasillo'), centerTitle: true),
      body: Column(
        children: [
          // Filtro Monitor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Text("Semestre: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _semestreSeleccionadoId,
                    hint: const Text("Seleccionar"),
                    items: _listaSemestres.map<DropdownMenuItem<String>>((s) {
                      return DropdownMenuItem<String>(
                        value: s['IdSemestre'].toString(),
                        child: Text(s['Nombre']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _semestreSeleccionadoId = val);
                        _cargarEstadisticas();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   Text("Desempeño: $_tituloSemestre", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const Text("Datos visibles para el pasillo.", style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 20),

                   GraficoPasillos(
                    datos: _datosGrafica,
                    titulo: "Ranking General",
                    subTitulo: "Acumulado total",
                    esVacio: _datosGrafica.isEmpty,
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  
                  // Desglose Monitor
                  ..._agruparPorMes().entries.map((entry) {
                    return ExpansionTile(
                      title: Text(entry.key.toUpperCase()),
                      children: entry.value.map((d) => ListTile(
                        title: Text(d['Pasillo']),
                        trailing: Text(double.parse(d['Promedio'].toString()).toStringAsFixed(1), 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      )).toList(),
                    );
                  }).toList(),
                ],
              ),
          ),
        ],
      ),
    );
  }
}