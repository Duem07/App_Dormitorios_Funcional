import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/tipo_culto_model.dart';
import 'package:gestion_dormitorios/services/culto_service.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert'; 

class GenerarQRMonitorScreen extends StatefulWidget {
  const GenerarQRMonitorScreen({super.key});

  @override
  State<GenerarQRMonitorScreen> createState() => _GenerarQRMonitorScreenState();
}

class _GenerarQRMonitorScreenState extends State<GenerarQRMonitorScreen> {
  final CultoService _cultoService = CultoService();
  
  // 1. Estado para manejar la lógica
  late Future<List<TipoCulto>> _futureTiposCulto;
  TipoCulto? _cultoSeleccionado;
  String? _qrData; // Aquí guardaremos el JSON para el QR

  @override
  void initState() {
    super.initState();
    // Cargamos los tipos de culto al iniciar la pantalla
    _futureTiposCulto = _cultoService.getTiposCulto();
  }

  /// Función para generar el JSON que irá en el código QR
  void _generarQR() {
    if (_cultoSeleccionado == null) {
      // Mostrar error si no se ha seleccionado un culto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un tipo de asistencia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtenemos la matrícula del monitor (ej. "222146")
    final monitorMatricula = Provider.of<UserProvider>(context, listen: false).matricula;

    // Creamos el mapa con los datos
    final Map<String, dynamic> dataParaQR = {
      'idTipoCulto': _cultoSeleccionado!.idTipoCulto,
      'registradoPor': monitorMatricula,
    };

    // Convertimos el mapa a un string JSON
    setState(() {
      _qrData = jsonEncode(dataParaQR);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Generar QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Usamos un ListView para evitar overflows en pantallas pequeñas
          child: ListView(
            shrinkWrap: true, // Para que se centre
            children: [
              // 2. Lógica condicional: Mostramos el QR o el icono
              if (_qrData != null)
                // --- VISTA DEL QR GENERADO ---
                Center(
                  child: Column(
                    children: [
                      Text('¡QR Generado!', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Los estudiantes ya pueden escanear este código para registrar su asistencia a: \n"${_cultoSeleccionado!.nombre}"',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: QrImageView( // El widget que genera la imagen del QR
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 250.0,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // --- VISTA INICIAL ---
                Center(
                  child: Icon(Icons.qr_code_scanner, size: 100, color: theme.colorScheme.primary.withOpacity(0.7)),
                ),
              
              const SizedBox(height: 30),

              // 3. El selector de tipo de culto
              _buildSelectorCultos(theme),

              const SizedBox(height: 20),

              // 4. El botón para generar
              ElevatedButton.icon(
                onPressed: _generarQR,
                icon: const Icon(Icons.qr_code),
                label: const Text('Generar QR de Asistencia'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              // Botón para limpiar (si ya se generó un QR)
              if (_qrData != null)
                TextButton(
                  onPressed: () => setState(() {
                    _qrData = null;
                    _cultoSeleccionado = null;
                  }),
                  child: const Text('Generar otro código'),
                )
            ],
          ),
        ),
      ),
    );
  }

  /// Un widget separado para el dropdown de cultos
  Widget _buildSelectorCultos(ThemeData theme) {
    return FutureBuilder<List<TipoCulto>>(
      future: _futureTiposCulto,
      builder: (context, snapshot) {
        // --- Estado de Carga ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // --- Estado de Error ---
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Error al cargar tipos de asistencia: ${snapshot.error ?? "No se encontraron datos."}',
              textAlign: TextAlign.center,
            ),
          );
        }

        // --- Estado de Éxito ---
        final tiposCulto = snapshot.data!;
        
        return DropdownButtonFormField<TipoCulto>(
          value: _cultoSeleccionado,
          decoration: InputDecoration(
            labelText: 'Tipo de Asistencia',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.church_outlined),
          ),
          hint: const Text('Selecciona una opción'),
          onChanged: (TipoCulto? newValue) {
            setState(() {
              _cultoSeleccionado = newValue;
              _qrData = null; // Limpiamos el QR si cambia la selección
            });
          },
          items: tiposCulto.map<DropdownMenuItem<TipoCulto>>((TipoCulto culto) {
            return DropdownMenuItem<TipoCulto>(
              value: culto,
              child: Text(culto.nombre),
            );
          }).toList(),
        );
      },
    );
  }
}
