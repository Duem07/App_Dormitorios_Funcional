import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Import for groupBy
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/cuarto_para_evaluar_model.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/registrar_limpieza_screen.dart';

class LimpiezaMonitorScreen extends StatefulWidget {
  const LimpiezaMonitorScreen({super.key});

  @override
  State<LimpiezaMonitorScreen> createState() => _LimpiezaMonitorScreenState();
}

class _LimpiezaMonitorScreenState extends State<LimpiezaMonitorScreen> {
  final LimpiezaService _limpiezaService = LimpiezaService();
  late Future<List<CuartoParaEvaluar>> _futureCuartos;

  @override
  void initState() {
    super.initState();
    // Cargamos la lista de cuartos al iniciar la pantalla
    _cargarCuartos();
  }

  /// Función para cargar o recargar la lista de cuartos desde la API
  void _cargarCuartos() {
    setState(() {
      _futureCuartos = _limpiezaService.obtenerCuartosConCalificacion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluar Limpieza')),
      body: FutureBuilder<List<CuartoParaEvaluar>>(
        future: _futureCuartos,
        builder: (context, snapshot) {
          // Mientras carga los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hubo un error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error al cargar cuartos: ${snapshot.error}', textAlign: TextAlign.center),
              )
            );
          }
          // Si no hay datos o la lista está vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron cuartos para evaluar.'));
          }

          // --- Agrupamos los cuartos por IdPasillo ---
          final cuartos = snapshot.data!;
          final cuartosAgrupados = groupBy(cuartos, (CuartoParaEvaluar c) => c.idPasillo);

          // Usamos ListView para poder tener encabezados y listas anidadas
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            // El número de items es el número de pasillos
            itemCount: cuartosAgrupados.keys.length,
            itemBuilder: (context, index) {
              final idPasillo = cuartosAgrupados.keys.elementAt(index);
              final cuartosDelPasillo = cuartosAgrupados[idPasillo]!;

              // Ordenamos los cuartos dentro del pasillo por número
              cuartosDelPasillo.sort((a, b) => a.numeroCuarto.compareTo(b.numeroCuarto));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Encabezado del Pasillo ---
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 24.0, bottom: 12.0), // Más espacio entre pasillos
                    child: Text(
                      'Pasillo $idPasillo', // Mostramos el ID del pasillo
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true, // Para que funcione dentro de otro ListView
                    physics: const NeverScrollableScrollPhysics(), // Deshabilitar scroll interno
                    itemCount: cuartosDelPasillo.length,
                    itemBuilder: (_, i) {
                      final cuarto = cuartosDelPasillo[i];
                      return Card(
                        margin: EdgeInsets.zero, // Quitamos margen para que el separator lo controle
                        child: ListTile(
                          leading: const Icon(Icons.meeting_room_outlined),
                          title: Text('Cuarto ${cuarto.numeroCuarto}'),
                          subtitle: Text(cuarto.ultimaCalificacion != null
                              ? 'Última Calif.: ${cuarto.ultimaCalificacion}' // Mostramos puntuación total
                              : 'Pendiente de evaluar'),
                          trailing: IconButton(
                            icon: Icon(Icons.cleaning_services, color: theme.colorScheme.primary),
                            tooltip: 'Evaluar limpieza',
                            onPressed: () async {
                              final bool? seGuardo = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrarLimpiezaScreen(
                                    idCuarto: cuarto.idCuarto, // Pasamos el ID real
                                  ),
                                ),
                              );
                              // Si se guardó, recargamos la lista para ver la nueva calificación
                              if (seGuardo == true && mounted) {
                                _cargarCuartos();
                              }
                            },
                          ),
                        ),
                      );
                    },
                     separatorBuilder: (context, index) => const SizedBox(height: 8.0), // Espacio entre cuartos
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

