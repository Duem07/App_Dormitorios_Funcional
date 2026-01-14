import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_dormitorios/services/amonestacion_service.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/models/amonestacion_preceptor_model.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/crear_amonestacion_screen.dart';

class AmonestacionesPreceptorScreen extends StatefulWidget {
  const AmonestacionesPreceptorScreen({super.key});

  @override
  State<AmonestacionesPreceptorScreen> createState() => _AmonestacionesPreceptorScreenState();
}

class _AmonestacionesPreceptorScreenState extends State<AmonestacionesPreceptorScreen> {
  final AmonestacionService _amonestacionService = AmonestacionService();
  late Future<List<AmonestacionPreceptor>> _futureAmonestaciones;

  @override
  void initState() {
    super.initState();
    _cargarAmonestaciones(); // Carga inicial
  }

  /// Llama al servicio para obtener/refrescar la lista de amonestaciones
  void _cargarAmonestaciones() {
    if (!mounted) return;
    setState(() {
      _futureAmonestaciones = _amonestacionService.getAllAmonestaciones();
    });
  }

  /// Navega a la pantalla para crear una nueva amonestación
  void _irACrearAmonestacion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearAmonestacionScreen()),
    ).then((seGuardo) {
      // Si se guardó una amonestación, recargamos la lista
      if (seGuardo == true && mounted) {
        _cargarAmonestaciones();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Amonestaciones'),
        centerTitle: true,
      ),
      body: RefreshIndicator( // Permite recargar deslizando
        onRefresh: () async => _cargarAmonestaciones(),
        child: FutureBuilder<List<AmonestacionPreceptor>>(
          future: _futureAmonestaciones,
          builder: (context, snapshot) {
            // Carga
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Error
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error al cargar amonestaciones:\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              ));
            }
            // Vacío
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay amonestaciones registradas.'));
            }

            // Lista
            final amonestaciones = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: amonestaciones.length,
              itemBuilder: (context, index) {
                return _buildAmonestacionCard(context, amonestaciones[index]);
              },
            );
          },
        ),
      ),
      // Botón para añadir nueva
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irACrearAmonestacion,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Nueva Amonestación'),
        tooltip: 'Registrar una nueva amonestación para un estudiante',
      ),
    );
  }

  /// Widget para mostrar la tarjeta de una amonestación
  Widget _buildAmonestacionCard(BuildContext context, AmonestacionPreceptor amon) {
    final theme = Theme.of(context);
    final colorNivel = _getColorNivel(amon.nivel); // Obtenemos color según nivel

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostramos estudiante y preceptor
            Text(
              'Estudiante: ${amon.estudianteNombre}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
             Text(
              'Registrada por: ${amon.preceptorNombre}',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const Divider(height: 16),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(amon.fecha)}', // Solo fecha
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Motivo: ${amon.motivo}'),
            const SizedBox(height: 12),
            // Nivel de la amonestación
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  amon.nivel,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                backgroundColor: colorNivel, // Color del chip según nivel
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                avatar: Icon(_getIconoNivel(amon.nivel), color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Funciones auxiliares de estilo ---
  Color _getColorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'leve': return Colors.green.shade600;
      case 'media': return Colors.orange.shade700;
      case 'grave': return Colors.red.shade700;
      default: return Colors.grey.shade500;
    }
  }

  IconData _getIconoNivel(String nivel) {
     switch (nivel.toLowerCase()) {
      case 'leve': return Icons.check_circle_outline;
      case 'media': return Icons.warning_amber_rounded;
      case 'grave': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }
} 
