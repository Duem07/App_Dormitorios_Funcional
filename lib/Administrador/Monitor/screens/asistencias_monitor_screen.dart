import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart'; // Necesario para UserProvider
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/asistencia_model.dart';
import 'package:gestion_dormitorios/services/asistencia_service.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/tipo_culto_model.dart';
import 'package:gestion_dormitorios/services/culto_service.dart';

class AsistenciasMonitorScreen extends StatefulWidget {
  const AsistenciasMonitorScreen({super.key});

  @override
  State<AsistenciasMonitorScreen> createState() => _AsistenciasMonitorScreenState();
}

class _AsistenciasMonitorScreenState extends State<AsistenciasMonitorScreen> with SingleTickerProviderStateMixin {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final CultoService _cultoService = CultoService(); 

  late TabController _tabController; // Controlador para las pestañas

  late Future<List<TipoCulto>> _futureTiposCulto;
  
  // Listas de datos
  Future<List<Asistencia>>? _futureAsistencias; 
  List<Asistencia> _listaFaltantes = [];
  bool _isLoadingFaltantes = false;

  TipoCulto? _cultoSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now(); 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Pestañas
    _futureTiposCulto = _cultoService.getTiposCulto();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // Cargar AMBAS listas (Asistentes y Faltantes)
  void _cargarDatos() {
    if (_cultoSeleccionado == null) return;
    
    // 1. Cargar Asistentes
    setState(() {
      _futureAsistencias = _asistenciaService.getAsistenciasCulto(
        idTipoCulto: _cultoSeleccionado!.idTipoCulto,
        fecha: _fechaSeleccionada, 
      );
    });

    // 2. Cargar Faltantes
    _cargarListaFaltantes();
  }

  void _cargarListaFaltantes() async {
    setState(() => _isLoadingFaltantes = true);
    try {
      final faltantes = await _asistenciaService.getFaltantesCulto(
        idTipoCulto: _cultoSeleccionado!.idTipoCulto,
        fecha: _fechaSeleccionada,
      );
      setState(() => _listaFaltantes = faltantes);
    } finally {
      if (mounted) setState(() => _isLoadingFaltantes = false);
    }
  }

  // Lógica del botón ROJO de reportar
  void _reportarFaltantes() async {
    final listaMatriculasLimpias = _listaFaltantes
        .map((e) => e.matricula)
        .where((m) => m != null && m.toString().trim().isNotEmpty) // Filtro vital
        .toList();

    if (listaMatriculasLimpias.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No hay matrículas válidas para reportar."), backgroundColor: Colors.orange));
       return;
    }

    // Obtener matrícula del monitor
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final monitorMatricula = userProvider.matricula;
    
    if(monitorMatricula == null || monitorMatricula.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No se identifica al monitor. Cierra sesion y vuelve a entrar."), backgroundColor: Colors.orange));
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Generar Reportes"),
        content: Text("Se generará un REPORTE DE DISCIPLINA a ${_listaFaltantes.length} estudiantes.\n\nSi alcanzan el límite (Vespertina: 2, Matutina: 3), se generará una AMONESTACIÓN automática.\n\n¿Estás seguro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SÍ, REPORTAR"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final exito = await _asistenciaService.generarReportesMasivos(
        matriculas: listaMatriculasLimpias, // Usamos la lista limpia
        idTipoCulto: _cultoSeleccionado!.idTipoCulto,
        fecha: _fechaSeleccionada,
        reportadoPor: monitorMatricula,
      );

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reportes generados correctamente"), backgroundColor: Colors.green));
          _cargarDatos(); // Recargar listas
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al generar reportes"), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020), 
      lastDate: DateTime.now(),  
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        _cargarDatos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencias'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: "Asistieron"),
            Tab(icon: Icon(Icons.cancel_outlined), text: "Faltaron"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selectores Comunes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSelectorCultos(),
                const SizedBox(height: 10),
                _buildSelectorFecha(context),
              ],
            ),
          ),
          
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // PESTAÑA 1: ASISTIERON
                _buildListaAsistentes(),

                // PESTAÑA 2: FALTARON
                _buildListaFaltantes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAsistentes() {
    if (_futureAsistencias == null) {
      return const Center(child: Text('Selecciona un culto para ver datos.'));
    }
    return FutureBuilder<List<Asistencia>>(
      future: _futureAsistencias,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nadie ha registrado asistencia aún.'));
        
        final lista = snapshot.data!;
        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (_, i) => ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green[100], child: const Icon(Icons.check, color: Colors.green)),
            title: Text(lista[i].nombreCompleto),
            subtitle: Text(lista[i].matricula),
          ),
        );
      },
    );
  }

  Widget _buildListaFaltantes() {
    if (_cultoSeleccionado == null) return const Center(child: Text('Selecciona un culto.'));
    if (_isLoadingFaltantes) return const Center(child: CircularProgressIndicator());
    
    return Column(
      children: [
        if (_listaFaltantes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _reportarFaltantes,
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text("REPORTAR A LOS ${_listaFaltantes.length} FALTANTES"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        Expanded(
          child: _listaFaltantes.isEmpty
              ? const Center(child: Text('¡Felicidades! Todos asistieron.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  itemCount: _listaFaltantes.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.red[100], child: const Icon(Icons.close, color: Colors.red)),
                    title: Text(_listaFaltantes[i].nombreCompleto),
                    subtitle: Text(_listaFaltantes[i].matricula),
                  ),
                ),
        ),
      ],
    );
  }

  // ... (Tus widgets _buildSelectorCultos y _buildSelectorFecha siguen igual, solo asegúrate de llamar a _cargarDatos() en el onChanged) ...
  
  Widget _buildSelectorCultos() {
    return FutureBuilder<List<TipoCulto>>(
      future: _futureTiposCulto,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        // Auto-seleccionar el primero si no hay selección
        if (_cultoSeleccionado == null && snapshot.data!.isNotEmpty) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
               setState(() {
                 _cultoSeleccionado = snapshot.data![0];
                 _cargarDatos();
               });
             }
           });
        }

        return DropdownButtonFormField<TipoCulto>(
          value: _cultoSeleccionado,
          decoration: InputDecoration(labelText: 'Tipo de Culto', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: snapshot.data!.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
          onChanged: (val) {
            setState(() {
              _cultoSeleccionado = val;
              _cargarDatos(); // <--- IMPORTANTE: Actualizar datos al cambiar
            });
          },
        );
      },
    );
  }

  Widget _buildSelectorFecha(BuildContext context) {
    return ListTile(
      tileColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: const Icon(Icons.calendar_today),
      title: Text(DateFormat('EEEE dd/MM/yyyy', 'es').format(_fechaSeleccionada).toUpperCase()),
      onTap: () => _seleccionarFecha(context),
    );
  }
}