import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/amonestacion_service.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/models/nivel_amonestacion_model.dart';

class CrearAmonestacionScreen extends StatefulWidget {
  const CrearAmonestacionScreen({super.key});

  @override
  State<CrearAmonestacionScreen> createState() => _CrearAmonestacionScreenState();
}

class _CrearAmonestacionScreenState extends State<CrearAmonestacionScreen> {
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final AmonestacionService _amonestacionService = AmonestacionService();
  final _formKey = GlobalKey<FormState>(); // Para validaciones

  // Estado para el dropdown de niveles
  late Future<List<NivelAmonestacion>> _futureNiveles;
  NivelAmonestacion? _nivelSeleccionado; // Nivel elegido

  bool _isLoading = false; // Para el botón de guardar

  @override
  void initState() {
    super.initState();
    // Cargamos los niveles al iniciar
    _futureNiveles = _amonestacionService.getNivelesAmonestacion();
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  /// Intenta guardar la nueva amonestación
  Future<void> _guardarAmonestacion() async {
    // Validamos el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
     // Validamos que se haya seleccionado un nivel
    if (_nivelSeleccionado == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Por favor, selecciona un nivel de amonestación.'), backgroundColor: Colors.orange),
       );
       return;
    }

    FocusScope.of(context).unfocus(); // Ocultar teclado

    // Obtenemos la ClaveEmpleado (o ID) del Preceptor logueado
    final preceptorId = Provider.of<UserProvider>(context, listen: false).usuarioID;

    if (preceptorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener tu ID de preceptor.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final resultado = await _amonestacionService.registrarAmonestacion(
        matriculaEstudiante: _matriculaController.text.trim(),
        clavePreceptor: preceptorId,
        idNivel: _nivelSeleccionado!.idNivel, // Usamos el ID del nivel seleccionado
        motivo: _motivoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'Amonestación guardada'), backgroundColor: Colors.green),
      );
      // Regresamos a la pantalla anterior indicando éxito
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Amonestación'),
        actions: [
          // Botón Guardar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                : IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: _guardarAmonestacion,
                    tooltip: 'Guardar Amonestación',
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
                'Datos de la Amonestación:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),

              // --- Campo Matrícula ---
              TextFormField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  labelText: 'Matrícula del Estudiante',
                  hintText: 'Ingresa la matrícula (ej. 222100)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa la matrícula.';
                  if (value.length != 6) return 'La matrícula debe tener 6 dígitos.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Dropdown Niveles ---
              FutureBuilder<List<NivelAmonestacion>>(
                future: _futureNiveles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text('Cargando niveles...'));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Error al cargar niveles. Intenta de nuevo.', style: TextStyle(color: Colors.red));
                  }

                  final niveles = snapshot.data!;
                  return DropdownButtonFormField<NivelAmonestacion>(
                    value: _nivelSeleccionado,
                    decoration: InputDecoration(
                       labelText: 'Nivel de Amonestación',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       prefixIcon: const Icon(Icons.priority_high_rounded),
                    ),
                    hint: const Text('Selecciona el nivel'),
                    items: niveles.map((NivelAmonestacion nivel) {
                      return DropdownMenuItem<NivelAmonestacion>(
                        value: nivel,
                        child: Text(nivel.nombre),
                      );
                    }).toList(),
                    onChanged: (NivelAmonestacion? newValue) {
                      setState(() {
                        _nivelSeleccionado = newValue;
                      });
                    },
                    // Validación simple: no puede ser nulo
                    validator: (value) => value == null ? 'Selecciona un nivel.' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- Campo Motivo ---
              TextFormField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo de la Amonestación',
                  hintText: 'Describe la razón detalladamente...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note_outlined),
                  alignLabelWithHint: true, // Para que el label se alinee con el hint
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa el motivo.';
                  if (value.length < 10) return 'El motivo debe tener al menos 10 caracteres.';
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
