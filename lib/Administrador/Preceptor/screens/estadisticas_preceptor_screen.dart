import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/grafico_estadisticas.dart'; // <--- IMPORTA EL WIDGET NUEVO

class EstadisticasPreceptorScreen extends StatefulWidget {
  const EstadisticasPreceptorScreen({super.key});

  @override
  State<EstadisticasPreceptorScreen> createState() => _EstadisticasPreceptorScreenState();
}

class _EstadisticasPreceptorScreenState extends State<EstadisticasPreceptorScreen> {
  final _limpiezaService = LimpiezaService();
  bool _isLoading = true;
  List<dynamic> _datosEnCurso = [];
  String _fechaInicio = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final resultado = await _limpiezaService.obtenerEstadisticas();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success'] == true) {
          // El Preceptor ve "enCurso"
          _datosEnCurso = resultado['data']['enCurso'] ?? [];
          _fechaInicio = resultado['data']['ultimoCorte'] ?? "";
        }
      });
    }
  }

  Future<void> _hacerCorte() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Publicar Calificaciones"),
        content: const Text("Al hacer corte:\n\n1. Los promedios actuales se harán visibles para todos.\n2. Se iniciará un nuevo ciclo de evaluación desde cero.\n\n¿Confirmar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );

    if (confirma == true) {
      setState(() => _isLoading = true);
      await _limpiezaService.realizarCorte(user.usuarioID);
      if(mounted) _cargarDatos(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Periodo')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Ciclo iniciado el: ${_fechaInicio.split('T')[0]}", style: TextStyle(color: Colors.blue[900]))),
                ]),
              ),
              const SizedBox(height: 20),
              
              GraficoPasillos(
                datos: _datosEnCurso,
                titulo: "Promedios en Curso",
                subTitulo: "Acumulado actual (No visible para alumnos aún).",
                esVacio: _datosEnCurso.isEmpty,
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.published_with_changes),
                  label: const Text("CERRAR PERIODO Y PUBLICAR"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _hacerCorte,
                ),
              )
            ],
          ),
    );
  }
}