import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/reporte_service.dart';

class CrearReporteScreen extends StatefulWidget {
  final String matriculaEstudiante; 
  const CrearReporteScreen({super.key, required this.matriculaEstudiante});

  @override
  State<CrearReporteScreen> createState() => _CrearReporteScreenState();
}

class _CrearReporteScreenState extends State<CrearReporteScreen> {
  final TextEditingController _motivoController = TextEditingController();
  final ReporteService _reporteService = ReporteService();
  final _formKey = GlobalKey<FormState>(); 
  bool _isLoading = false;

  // --- CONFIGURACIÓN DE TIPOS DE REPORTE ---
  // 1: Limpieza, 2: Disciplina, 3: Daños materiales
  final List<Map<String, dynamic>> _tiposReporte = [
    {'id': 1, 'nombre': 'Limpieza', 'icon': Icons.cleaning_services_outlined},
    {'id': 2, 'nombre': 'Disciplina', 'icon': Icons.gavel_outlined},
    {'id': 3, 'nombre': 'Daños materiales', 'icon': Icons.build_outlined},
  ];

  int? _idTipoSeleccionado; // Variable para guardar la selección

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _guardarReporte() async {
    // 1. Validar formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. Validar Dropdown
    if (_idTipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona el TIPO de reporte.'), backgroundColor: Colors.orange),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // 3. Obtener matrícula del Monitor
    final monitorMatricula = Provider.of<UserProvider>(context, listen: false).matricula;

    if (monitorMatricula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener tu matrícula.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 4. Enviar datos AL SERVICIO (Incluyendo idTipoReporte)
      final resultado = await _reporteService.crearReporte(
        matriculaReportado: widget.matriculaEstudiante,
        reportadoPor: monitorMatricula,
        tipoUsuarioReportante: 'Monitor', // Rol fijo
        motivo: _motivoController.text.trim(),
        idTipoReporte: _idTipoSeleccionado!, // <--- AQUÍ SE CORRIGE EL ERROR
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Reporte guardado'), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Reporte'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                : IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: _guardarReporte,
                    tooltip: 'Guardar Reporte',
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Form( 
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reporte para el estudiante:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.matriculaEstudiante, 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),

              // --- NUEVO CAMPO: DROPDOWN TIPO DE REPORTE ---
              DropdownButtonFormField<int>(
                value: _idTipoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Reporte',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                hint: const Text('Selecciona el tipo'),
                items: _tiposReporte.map((tipo) {
                  return DropdownMenuItem<int>(
                    value: tipo['id'] as int,
                    child: Row(
                      children: [
                        Icon(tipo['icon'], size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 10),
                        Text(tipo['nombre']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _idTipoSeleccionado = valor;
                  });
                },
                validator: (value) => value == null ? 'Selecciona un tipo.' : null,
              ),
              const SizedBox(height: 16),

              // --- CAMPO MOTIVO ---
              TextFormField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo del Reporte',
                  hintText: 'Describe la razón detalladamente...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 5, 
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done, 
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa el motivo del reporte.';
                  }
                  if (value.length < 5) return 'El motivo es muy corto.';
                  return null; 
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}