import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/reporte_service.dart';
import 'package:gestion_dormitorios/Estudiantes/models/reporte_model.dart';

class ReportesAlumnoScreen extends StatefulWidget {
  const ReportesAlumnoScreen({super.key});

  @override
  State<ReportesAlumnoScreen> createState() => _ReportesAlumnoScreenState();
}

class _ReportesAlumnoScreenState extends State<ReportesAlumnoScreen> {
  Future<List<Reporte>>? _futureReportes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarReportes());
  }

  void _cargarReportes() {
    final matricula = Provider.of<UserProvider>(context, listen: false).usuarioID;
    if (matricula.isNotEmpty) {
      final service = ReporteService();
      setState(() {
        _futureReportes = service.getReportesPorEstudiante(matricula);
      });
    }else {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        centerTitle: true,
      ),
      body: _futureReportes == null
          ? const Center(child: Text("Cargando información del usuario..."))
          : FutureBuilder<List<Reporte>>(
              future: _futureReportes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No tienes reportes registrados.'));
                }

                final reportesAprobados = snapshot.data!
                  .where((reporte) => reporte.estado.toLowerCase() == 'aprobado')
                  .toList();

                if(reportesAprobados.isEmpty){
                  return const Center(child: Text('No tiene reportes aprobados'));
                }

                final reportes = snapshot.data!;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    const double breakpoint = 600.0;
                    if (constraints.maxWidth < breakpoint) {
                      return _buildPhoneLayout(reportes);
                    } else {
                      return _buildTabletLayout(reportes, constraints.maxWidth);
                    }
                  },
                );
              },
            ),
    );
  }

  // Layout para Teléfonos
  Widget _buildPhoneLayout(List<Reporte> reportes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reportes.length,
      itemBuilder: (context, index) => _buildReporteCard(context, reportes[index]),
    );
  }

  // Layout para Tablets
  Widget _buildTabletLayout(List<Reporte> reportes, double width) {
    final crossAxisCount = (width / 350).floor().clamp(2, 4); // Entre 2 y 4 columnas
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.8,
      ),
      itemCount: reportes.length,
      itemBuilder: (context, index) => _buildReporteCard(context, reportes[index]),
    );
  }

  Widget _buildReporteCard(BuildContext context, Reporte reporte) {
    final fechaFormateada = reporte.fecha != null
      ? DateFormat('dd/MM/yyyy').format(reporte.fecha!)
      : 'Fecha no disponible';


    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha: $fechaFormateada',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(reporte.motivo),
            const SizedBox(height: 4),
            Text('Reportado por: ${reporte.reportadoPor}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}