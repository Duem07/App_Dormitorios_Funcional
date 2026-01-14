import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/reporte_service.dart';

class CrearReportePreceptorScreen extends StatefulWidget {
  const CrearReportePreceptorScreen({super.key});

  @override
  State<CrearReportePreceptorScreen> createState() => _CrearReportePreceptorScreenState();
}

class _CrearReportePreceptorScreenState extends State<CrearReportePreceptorScreen> {
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final ReporteService _reporteService = ReporteService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // --- CONFIGURACIÓN DE TIPOS DE REPORTE ---
  // Estos IDs deben coincidir con tu Base de Datos SQL:
  // 1: Limpieza, 2: Disciplina, 3: Daños materiales
  final List<Map<String, dynamic>> _tiposReporte = [
    {'id': 1, 'nombre': 'Limpieza', 'icon': Icons.cleaning_services_outlined},
    {'id': 2, 'nombre': 'Disciplina', 'icon': Icons.gavel_outlined},
    {'id': 3, 'nombre': 'Daños materiales', 'icon': Icons.build_outlined},
  ];

  int? _idTipoSeleccionado; // Aquí guardamos la selección (1, 2 o 3)

  @override
  void dispose() {
    _matriculaController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _guardarReporte() async {
    // 1. Validaciones del formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. Validación manual del Dropdown
    if (_idTipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un TIPO de reporte.'), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus(); // Ocultar teclado
    
    // 3. Obtener ID del Preceptor
    final preceptorId = Provider.of<UserProvider>(context, listen: false).usuarioID;

    if (preceptorId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de sesión.'), backgroundColor: Colors.red));
       return;
    }

    setState(() => _isLoading = true);

    try {
      // 4. Llamar al servicio CON el idTipoReporte
      final resultado = await _reporteService.crearReporte(
        matriculaReportado: _matriculaController.text.trim(),
        reportadoPor: preceptorId,
        tipoUsuarioReportante: 'Preceptor', 
        motivo: _motivoController.text.trim(),
        idTipoReporte: _idTipoSeleccionado!, // <--- ¡AQUÍ ESTÁ LA SOLUCIÓN!
      );

      if (!mounted) return;

      // 5. Mensaje de Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Reporte guardado correctamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4), // Damos tiempo para leer si hubo amonestación automática
        ),
      );
      Navigator.pop(context, true); // Regresamos true para recargar la lista anterior

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reporte (Preceptor)'),
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
              Text('Datos del Reporte:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),

              // --- CAMPO MATRÍCULA ---
              TextFormField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  labelText: 'Matrícula del Estudiante',
                  hintText: 'Ej. 222100',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_search_outlined),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa la matrícula.';
                  if (value.length < 5) return 'Matrícula inválida.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- CAMPO TIPO DE REPORTE (DROPDOWN) ---
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
                  hintText: 'Describe detalladamente la falta...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa el motivo.';
                  if (value.length < 5) return 'Sé más descriptivo.';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}