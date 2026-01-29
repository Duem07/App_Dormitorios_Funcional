import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/grafico_estadisticas.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final _limpiezaService = LimpiezaService();
  bool _isLoading = true;
  
  // Nuevas variables de datos
  List<dynamic> _datosGrafica = []; // El promedio general del semestre
  List<dynamic> _datosMensuales = []; // El desglose mes a mes
  List<dynamic> _listaSemestres = []; // Para el dropdown
  
  String? _semestreSeleccionadoId;
  String _tituloSemestre = "Cargando...";

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    // 1. Obtener lista de semestres
    final semestres = await _limpiezaService.obtenerSemestres();
    
    if (mounted) {
      setState(() {
        _listaSemestres = semestres;
        
        // Seleccionar por defecto el semestre ACTIVO (o el primero si no hay)
        if (_semestreSeleccionadoId == null && semestres.isNotEmpty) {
           final activo = semestres.firstWhere(
             (s) => s['Activo'] == true, 
             orElse: () => semestres.first
           );
           _semestreSeleccionadoId = activo['IdSemestre'].toString();
        }
      });
      // 2. Cargar estadísticas
      _cargarEstadisticas();
    }
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    
    final resultado = await _limpiezaService.obtenerEstadisticas(
      idSemestre: _semestreSeleccionadoId
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success'] == true) {
          _datosGrafica = resultado['data']['grafica'] ?? [];
          _datosMensuales = resultado['data']['mensual'] ?? [];
          _tituloSemestre = resultado['data']['titulo'] ?? "Periodo";
        }
      });
    }
  }

  String _obtenerGanador() {
    if (_datosGrafica.isEmpty) return "Nadie";
    var ganador = _datosGrafica.reduce((curr, next) {
      double p1 = double.tryParse(curr['Promedio'].toString()) ?? 0;
      double p2 = double.tryParse(next['Promedio'].toString()) ?? 0;
      return p1 > p2 ? curr : next;
    });
    return ganador['Pasillo'] ?? "Nadie";
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
      appBar: AppBar(
        title: const Text('Resultados Oficiales'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- FILTRO DE SEMESTRE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.green),
                const SizedBox(width: 10),
                const Text("Ver ciclo: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _semestreSeleccionadoId,
                    hint: const Text("Seleccionar..."),
                    items: _listaSemestres.map<DropdownMenuItem<String>>((semestre) {
                      final bool esActivo = semestre['Activo'] == true;
                      return DropdownMenuItem<String>(
                        value: semestre['IdSemestre'].toString(),
                        child: Text(
                          semestre['Nombre'] + (esActivo ? " (Actual)" : ""),
                          style: TextStyle(
                            fontWeight: esActivo ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
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

          // --- CONTENIDO ---
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarTodo,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                     // TARJETA GANADOR
                     Container(
                       padding: const EdgeInsets.all(16),
                       margin: const EdgeInsets.only(bottom: 20),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.green.shade200),
                         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                           const SizedBox(width: 15),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text("Líder del Semestre $_tituloSemestre", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                 Text(_obtenerGanador(), style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 22)),
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),

                     GraficoPasillos(
                      datos: _datosGrafica,
                      titulo: "Ranking General",
                      subTitulo: "Promedio acumulado del $_tituloSemestre",
                      esVacio: _datosGrafica.isEmpty,
                    ),

                    const SizedBox(height: 25),
                    const Text("Desglose Mensual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // LISTA DE MESES
                    if (_datosMensuales.isEmpty)
                      const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Aún no hay datos mensuales.")))
                    else
                      ..._agruparPorMes().entries.map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: const Icon(Icons.calendar_month, color: Colors.green),
                            title: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: entry.value.map((d) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(d['Pasillo']),
                                        Text(double.parse(d['Promedio'].toString()).toStringAsFixed(1), 
                                          style: const TextStyle(fontWeight: FontWeight.bold))
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                      
                    const SizedBox(height: 20),
                    const Center(child: Text("Nota: Los sábados no cuentan para el promedio.", style: TextStyle(color: Colors.grey, fontSize: 11))),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
}