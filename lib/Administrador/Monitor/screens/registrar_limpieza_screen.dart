import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/criterio_limpieza_model.dart';

class RegistrarLimpiezaScreen extends StatefulWidget {
  final int idCuarto;

  const RegistrarLimpiezaScreen({super.key, required this.idCuarto});

  @override
  State<RegistrarLimpiezaScreen> createState() => _RegistrarLimpiezaScreenState();
}

class _RegistrarLimpiezaScreenState extends State<RegistrarLimpiezaScreen> {
  final LimpiezaService _limpiezaService = LimpiezaService();
  late Future<List<CriterioLimpieza>> _futureCriterios;

  int _ordenGeneral = 0;
  int _disciplina = 0;
  final TextEditingController _observacionesController = TextEditingController();

  List<CriterioLimpieza> _criteriosList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureCriterios = _limpiezaService.obtenerCriterios();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardarLimpieza() async {
    // 1. Validaciones previas
    if (_criteriosList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espera a que carguen los criterios.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final monitorMatricula = userProvider.matricula;

    if (monitorMatricula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se identificó al monitor.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await _limpiezaService.registrarLimpieza(
        idCuarto: widget.idCuarto,
        evaluadoPorMatricula: monitorMatricula,
        criterios: _criteriosList,
        ordenGeneral: _ordenGeneral,
        disciplina: _disciplina,
        observaciones: _observacionesController.text,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'Guardado con éxito'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluar Cuarto ${widget.idCuarto}'),
        actions: [
          // Mantenemos el botón aquí, pero su estado habilitado/deshabilitado dependerá de _isLoading
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.save),
                    // El truco: habilitamos el botón siempre, la validación se hace dentro de la función
                    onPressed: _guardarLimpieza, 
                    tooltip: 'Guardar',
                  ),
          ),
        ],
      ),
      body: FutureBuilder<List<CriterioLimpieza>>(
        future: _futureCriterios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay criterios definidos.'));
          }

          // Solo llenamos la lista si está vacía (primera carga)
          if (_criteriosList.isEmpty) {
            _criteriosList = snapshot.data!;
            // NOTA: No llamamos setState aquí para evitar reconstrucciones infinitas
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Criterios Matutinos (Máx 80 pts)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              
              // Lista dinámica de criterios
              ..._criteriosList.map((criterio) => _buildCriterioRow(criterio)).toList(),

              const Divider(height: 40, thickness: 2),

              const Text('Evaluación Nocturna (Máx 20 pts)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              
              _buildAdditionalScoreRow('Orden General (Noche)', _ordenGeneral, (val) => setState(() => _ordenGeneral = val)),
              _buildAdditionalScoreRow('Disciplina (Noche)', _disciplina, (val) => setState(() => _disciplina = val)),

              const SizedBox(height: 20),
              TextField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
              ),
              // Espacio extra al final para que el botón flotante no tape nada si decidimos usar uno
              const SizedBox(height: 80), 
            ],
          );
        },
      ),
    );
  }

  Widget _buildCriterioRow(CriterioLimpieza criterio) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(criterio.descripcion, style: const TextStyle(fontSize: 16))),
            DropdownButton<int>(
              value: criterio.calificacion,
              underline: Container(), // Quita la línea fea de abajo
              items: List.generate(11, (index) => index).map((val) { // 0 a 10
                return DropdownMenuItem(value: val, child: Text(val.toString()));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => criterio.calificacion = val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalScoreRow(String label, int value, Function(int) onChanged) {
    return Card(
      color: Colors.blue[50], // Un color ligero para diferenciar la noche
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            DropdownButton<int>(
              value: value,
              underline: Container(),
              items: List.generate(11, (index) => index).map((val) {
                return DropdownMenuItem(value: val, child: Text(val.toString()));
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}