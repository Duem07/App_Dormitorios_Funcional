import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/amonestacion_service.dart';
import 'package:gestion_dormitorios/Estudiantes/models/amonestacion_model.dart';

class AmonestacionesScreen extends StatefulWidget {
  const AmonestacionesScreen({super.key});

  @override
  State<AmonestacionesScreen> createState() => _AmonestacionesScreenState();
}

class _AmonestacionesScreenState extends State<AmonestacionesScreen> {
  Future<Map<String, dynamic>>? _futureAmonestaciones;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarAmonestaciones());
  }

  void _cargarAmonestaciones() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matricula = userProvider.matricula;

    if (matricula.isNotEmpty) {
      final service = AmonestacionService();
      setState(() {
        _futureAmonestaciones = service.getAmonestacionesPorEstudiante(matricula);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amonestaciones'),
        centerTitle: true,
      ),
      body: _futureAmonestaciones == null
          ? const Center(child: Text("Cargando información del usuario..."))
          : FutureBuilder<Map<String, dynamic>>(
              future: _futureAmonestaciones,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null || snapshot.data!['success'] == false) {
                  return Center(child: Text(snapshot.data?['message'] ?? 'No hay amonestaciones.'));
                }

                final List<Amonestacion> amonestaciones = (snapshot.data!['data'] as List)
                    .map((json) => Amonestacion.fromJson(json))
                    .toList();

                if (amonestaciones.isEmpty) {
                  return const Center(child: Text('No hay amonestaciones registradas'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    const double breakpoint = 600.0;
                    if (constraints.maxWidth < breakpoint) {
                      // Pantallas estrechas (teléfono vertical)
                      return _buildPhoneLayout(amonestaciones);
                    } else {
                      // Pantallas anchas (tablet, teléfono horizontal)
                      return _buildTabletLayout(amonestaciones, constraints.maxWidth);
                    }
                  },
                );
              },
            ),
    );
  }
Widget _buildPhoneLayout(List<Amonestacion> amonestaciones) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: amonestaciones.length,
    itemBuilder: (context, index) {
      // Le decimos a la tarjeta que NO está en una GridView
      return _buildAmonestacionCard(context, amonestaciones[index], isGridView: false);
    },
  );
}

Widget _buildTabletLayout(List<Amonestacion> amonestaciones, double width) {
  final crossAxisCount = (width / 350).floor().clamp(2, 4);

  return GridView.builder(
    padding: const EdgeInsets.all(24),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
    ),
    itemCount: amonestaciones.length,
    itemBuilder: (context, index) {
     
      return _buildAmonestacionCard(context, amonestaciones[index], isGridView: true);
    },
  );
}

 
Widget _buildAmonestacionCard(BuildContext context, Amonestacion amon, {bool isGridView = false}) {
  final color = _getColorSegunSeveridad(amon.severidad);
  final icono = _getIconoSegunSeveridad(amon.severidad);

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha: ${DateFormat('dd/MM/yyyy').format(amon.fecha)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Razón: ${amon.razon}'),
          const SizedBox(height: 4),
          Text('Registrada por: ${amon.preceptor}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          
          if (isGridView) const Spacer(),
          
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Severidad: ${amon.severidad}',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              Icon(icono, color: color),
            ],
          ),
        ],
      ),
    ),
  );
}
  Color _getColorSegunSeveridad(String s) {
    switch (s.toLowerCase()) {
      case 'leve': return Colors.green;
      case 'media': return Colors.orange; // 'Moderada' en tu UI, 'Media' en la BD
      case 'grave': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getIconoSegunSeveridad(String s) {
    switch (s.toLowerCase()) {
      case 'leve': return Icons.check_circle_outline;
      case 'media': return Icons.warning_amber_rounded;
      case 'grave': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }
}