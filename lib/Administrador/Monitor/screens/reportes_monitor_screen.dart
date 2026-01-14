import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
// Importamos el servicio y los modelos necesarios
import 'package:gestion_dormitorios/services/reporte_service.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/reporte_monitor_model.dart';
// Importamos la pantalla para crear reporte
import 'package:gestion_dormitorios/Administrador/Monitor/screens/crear_reporte_screen.dart';

class ReportesMonitorScreen extends StatefulWidget {
  const ReportesMonitorScreen({super.key});

  @override
  State<ReportesMonitorScreen> createState() => _ReportesMonitorScreenState();
}

class _ReportesMonitorScreenState extends State<ReportesMonitorScreen> {
  final TextEditingController _matriculaController = TextEditingController();
  final ReporteService _reporteService = ReporteService();

  // Estado para manejar la búsqueda
  Future<List<ReporteMonitor>>? _futureReportes;
  String? _matriculaBuscada; // Guardamos la matrícula que se buscó
  bool _isLoading = false;
  String _mensaje = 'Ingresa una matrícula para ver sus reportes.'; // Mensaje inicial

  @override
  void dispose() {
    _matriculaController.dispose();
    super.dispose();
  }

  /// Función para iniciar la búsqueda de reportes
  void _buscarReportes() {
    final matricula = _matriculaController.text.trim();
    if (matricula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa una matrícula.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Oculta el teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true; // Mostramos indicador mientras busca
      _futureReportes = _reporteService.buscarReportesMonitor(matricula);
      _matriculaBuscada = matricula; // Guardamos la matrícula buscada
      _mensaje = ''; // Limpiamos el mensaje inicial
    });

    // Manejamos el futuro para quitar el loading y actualizar mensaje si hay error/no hay datos
    _futureReportes!.then((_) {
      if (mounted) setState(() => _isLoading = false);
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Mostramos el error específico que viene del service
          _mensaje = '$error'; 
        });
      }
    });
  }

  /// Navega a la pantalla para crear un nuevo reporte
  void _irACrearReporte() {
    if (_matriculaBuscada == null || _matriculaBuscada!.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero busca una matrícula válida.'), backgroundColor: Colors.orange),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        // Le pasamos la matrícula buscada a la pantalla de creación
        builder: (_) => CrearReporteScreen(matriculaEstudiante: _matriculaBuscada!),
      ),
    ).then((seGuardo) {
      // Si la pantalla de crear devuelve true, refrescamos la búsqueda actual
      if (seGuardo == true) {
        _buscarReportes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Reportes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Campo de Búsqueda ---
            TextField(
              controller: _matriculaController,
              decoration: InputDecoration(
                labelText: 'Matrícula del Estudiante',
                hintText: 'Ej. 222100',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                // Añadimos un botón de limpiar
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _matriculaController.clear();
                    setState(() {
                      _futureReportes = null; // Limpiamos resultados
                      _matriculaBuscada = null;
                      _mensaje = 'Ingresa una matrícula para ver sus reportes.';
                    });
                  },
                ),
              ),
              keyboardType: TextInputType.number, // Teclado numérico
              textInputAction: TextInputAction.search, // Cambiado para claridad
              onSubmitted: (_) => _buscarReportes(), // Permite buscar con Enter
            ),
            const SizedBox(height: 16),
            // --- Botón de Buscar ---
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _buscarReportes, // Deshabilitado mientras carga
              icon: _isLoading 
                   ? Container(
                       width: 24, 
                       height: 24, 
                       padding: const EdgeInsets.all(2.0), 
                       child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                     ) 
                   : const Icon(Icons.search),
              label: Text(_isLoading ? 'Buscando...' : 'Buscar Reportes'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Botón ancho
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              height: MediaQuery.of(context).size.height * 0.5, 
              child: _isLoading && _futureReportes == null // Solo muestra loading al inicio
                  ? const Center(child: CircularProgressIndicator()) 
                  : (_futureReportes == null
                      ? Center(child: Text(_mensaje, textAlign: TextAlign.center)) // Mensaje inicial o de error
                      : FutureBuilder<List<ReporteMonitor>>(
                          future: _futureReportes,
                          builder: (context, snapshot) {
                            // No mostramos loading aquí, ya lo controla _isLoading
                            if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                               return const Center(child: CircularProgressIndicator());
                            }
                            
                            // Si el future completó con error (ya manejado en _buscarReportes)
                            if (snapshot.hasError && _mensaje.isNotEmpty) {
                               return Center(child: Text(_mensaje, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)));
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text(
                                _mensaje.isNotEmpty ? _mensaje : 'No se encontraron reportes para la matrícula $_matriculaBuscada.',
                                textAlign: TextAlign.center,
                              ));
                            }

                            final reportes = snapshot.data!;
                            // Si hay datos, mostramos la lista
                            return ListView.builder(
                              itemCount: reportes.length,
                              itemBuilder: (context, index) {
                                return _buildReporteCard(context, reportes[index]);
                              },
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
      // --- Botón Flotante para Crear Reporte ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _irACrearReporte, // Deshabilitado si está buscando
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Reporte'),
        tooltip: 'Crear un nuevo reporte para el estudiante buscado',
      ),
    );
  }

  /// Widget para mostrar la tarjeta de un reporte
  Widget _buildReporteCard(BuildContext context, ReporteMonitor reporte) {
    final theme = Theme.of(context);
    // Usamos los colores definidos previamente para consistencia
    final colorEstado = _colorEstado(reporte.estado); 
    final iconoEstado = _iconoEstado(reporte.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudiante: ${reporte.nombreEstudianteReportado}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
             Text(
              'Matrícula: ${_matriculaBuscada ?? 'N/A'}', // Muestra la matrícula buscada
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 16),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(reporte.fechaReporte)}', // Incluimos hora
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Motivo: ${reporte.motivo}'),
            const SizedBox(height: 8),
            Text(
              'Reportado por: ${reporte.reportadoPorNombre}',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Align( // Alineamos la etiqueta de estado a la derecha
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconoEstado, size: 16, color: colorEstado),
                    const SizedBox(width: 6),
                    Text(
                      reporte.estado,
                      style: TextStyle(color: colorEstado, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Funciones auxiliares de estilo (copiadas de ReportesAlumnoScreen) ---
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado': return Colors.green;
      case 'pendiente': return Colors.orange;
      case 'rechazado': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado': return Icons.check_circle_outline;
      case 'pendiente': return Icons.hourglass_empty_rounded;
      case 'rechazado': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }
}

