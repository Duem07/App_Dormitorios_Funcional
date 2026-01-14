import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; 
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/cuarto_para_evaluar_model.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/DetalleLimpiezaModal.dart';

class LimpiezaPreceptorScreen extends StatefulWidget {
  const LimpiezaPreceptorScreen({super.key});

  @override
  State<LimpiezaPreceptorScreen> createState() => _LimpiezaPreceptorScreenState();
}

class _LimpiezaPreceptorScreenState extends State<LimpiezaPreceptorScreen> {
  final LimpiezaService _limpiezaService = LimpiezaService();
  late Future<List<CuartoParaEvaluar>> _futureCuartos;

  @override
  void initState() {
    super.initState();
    _cargarCuartos(); 
  }

  void _cargarCuartos() {
    if (!mounted) return;
    setState(() {
      _futureCuartos = _limpiezaService.obtenerCuartosConCalificacion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Limpieza (General)'),
        centerTitle: true,
      ),
      body: RefreshIndicator( // Permite recargar deslizando
        onRefresh: () async => _cargarCuartos(),
        child: FutureBuilder<List<CuartoParaEvaluar>>(
          future: _futureCuartos,
          builder: (context, snapshot) {
            // Carga
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Error
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error al cargar datos:\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              ));
            }
            // Vacío
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay cuartos registrados o no se pudo cargar la información.'));
            }

            // --- Agrupamos los cuartos por Pasillo ---
            final cuartos = snapshot.data!;
            // Usamos groupBy del paquete 'collection'
            final Map<int?, List<CuartoParaEvaluar>> cuartosAgrupados =
                 groupBy(cuartos, (cuarto) => cuarto.idPasillo);

            // Obtenemos las claves (IDs de Pasillo) y las ordenamos
            final List<int?> pasilloIds = cuartosAgrupados.keys.toList()
              ..sort((a, b) => (a ?? -1).compareTo(b ?? -1)); // Ordena los pasillos

            // --- Construimos la lista agrupada ---
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              // Número de secciones (pasillos) + los items dentro de cada sección
              itemCount: pasilloIds.length,
              itemBuilder: (context, index) {
                 final pasilloId = pasilloIds[index];
                 final cuartosDelPasillo = cuartosAgrupados[pasilloId]!;

                 // Devolvemos una Columna por cada Pasillo
                 return Card(
                  elevation: 2.0,
                  margin: EdgeInsets.only(top: index == 0 ? 0 : 16.0, bottom: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias, // Para que el contenido respete los bordes redondeados
                  child: ExpansionTile(
                    // El título "Pasillo X" ahora es el label que se puede "apachar"
                    title: Text(
                       'Pasillo ${pasilloId ?? "Desconocido"}',
                       style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                     ),
                  subtitle: Text('${cuartosDelPasillo.length} cuartos en este pasillo'),
                  leading: Icon(Icons.meeting_room_outlined, color: theme.colorScheme.primary),
                  initiallyExpanded: index == 0, // El primer pasillo empieza abierto
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Padding para los cuartos
                    // Los "hijos" (children) son la lista de cuartos de ese pasillo
                  children: cuartosDelPasillo.map((cuarto) {
                       // Reutilizamos el widget de la tarjeta del cuarto
                       return _buildCuartoCard(context, cuarto); 
                    }).toList(),
                   ),
                 ); 
              },
            );
          },
        ),
      ),
    );
  }

  /// Widget para mostrar la tarjeta de un cuarto con su última calificación
  Widget _buildCuartoCard(BuildContext context, CuartoParaEvaluar cuarto) {
    final theme = Theme.of(context);
    final bool evaluado = cuarto.ultimaCalificacion != null;
    
    // Color del estado
    final Color? statusColor = evaluado 
        ? (cuarto.ultimaCalificacion! >= 70 ? Colors.green : Colors.orange) 
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.4))
      ),
      child: InkWell( // <--- 1. Envolvemos el ListTile en un InkWell para el efecto de toque
        borderRadius: BorderRadius.circular(8),
        onTap: !evaluado 
            ? null // Si no está evaluado, no hace nada
            : () {
                // 2. Aquí abrimos el Modal
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Importante para que el modal pueda ser alto
                  backgroundColor: Colors.transparent, // Para ver las esquinas redondeadas
                  builder: (context) => DetalleLimpiezaModal(
                    idCuarto: cuarto.idCuarto,         // Pasamos el ID real
                    numeroCuarto: cuarto.numeroCuarto.toString(), // Pasamos el número visual
                  ),
                );
              },
        child: ListTile(
          leading: Icon(Icons.meeting_room_outlined, color: theme.colorScheme.secondary),
          title: Text('Cuarto ${cuarto.numeroCuarto}'),
          subtitle: Text(
            evaluado
              ? 'Última Calificación: ${cuarto.ultimaCalificacion}/100'
              : 'Pendiente de evaluación',
            style: TextStyle(color: evaluado ? null : Colors.grey[600]),
          ),
          trailing: Icon(
            evaluado 
                ? (cuarto.ultimaCalificacion! >= 70 ? Icons.check_circle_outline : Icons.warning_amber_rounded) 
                : Icons.hourglass_empty_rounded,
            color: statusColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
