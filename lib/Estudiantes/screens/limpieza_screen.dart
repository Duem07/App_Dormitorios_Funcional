import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/Estudiantes/models/limpieza_model.dart';

class LimpiezaScreen extends StatefulWidget {
  const LimpiezaScreen({super.key});

  @override
  State<LimpiezaScreen> createState() => _LimpiezaScreenState();
}

class _LimpiezaScreenState extends State<LimpiezaScreen> {
  Future<LimpiezaReporte?>? _reporteFuture;

  final Map<String, IconData> _iconosCriterios = {
    'Mesas y libreros': Icons.table_chart_outlined,
    'Lavabo y espejos': Icons.countertops_outlined,
    'Cajones y zapatos': Icons.inventory_2_outlined,
    'Piso barrido y trapeado': Icons.cleaning_services_outlined,
    'Camas tendidas': Icons.bed_outlined,
    'Orden inodoro': Icons.wc_outlined,
    'Clasificación de basura': Icons.recycling_outlined,
    'Ventanas': Icons.window_outlined,
    'Regaderas': Icons.shower_outlined,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _obtenerDatos());
  }

  void _obtenerDatos() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final idCuarto = userProvider.idCuarto;

    if (idCuarto != null) {
      final service = LimpiezaService();
      setState(() {
        _reporteFuture = service.obtenerUltimaLimpieza(idCuarto);
      });
    } else {
      print("Error: No se encontró IdCuarto para el usuario.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limpieza del Día'),
        centerTitle: true,
      ),
      body: _reporteFuture == null
          ? const Center(child: Text("Cargando información del usuario..."))
          : FutureBuilder<LimpiezaReporte?>(
              future: _reporteFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   print("Error en FutureBuilder: ${snapshot.error}"); // Log para depuración
                  return Center(child: Text('Error al cargar los datos: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Aún no hay registros de limpieza para tu cuarto.'));
                }

                final reporte = snapshot.data!;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    const double breakpoint = 600.0;
                    if (constraints.maxWidth < breakpoint) {
                      return _buildPhoneLayout(reporte);
                    } else {
                      return _buildTabletLayout(reporte);
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _buildInfoCard(LimpiezaReporte reporte) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registro de limpieza y disciplina', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business_outlined, 'Hogar de Varones Universitarios'),
            _buildInfoRow(Icons.room_outlined, 'Cuarto: ${reporte.numeroCuarto}'),
            _buildInfoRow(Icons.calendar_today_outlined, 'Fecha: ${DateFormat('dd/MM/yyyy').format(reporte.fecha)}'),
            _buildInfoRow(Icons.person_outline, 'Evaluado por: ${reporte.evaluadoPor}'), // Cambiado de 'Responsable'
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaList(LimpiezaReporte reporte) {
    return Column(
      children: [
        ...reporte.detalle.map((item) {
          final icon = _iconosCriterios[item.criterio] ?? Icons.rule;
          return _buildCriterioRow(icon, item.criterio, item.calificacion.toString());
        }).toList(),

        const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),

        _buildCriterioRow(Icons.calculate_outlined, 'Subtotal', reporte.subtotal.toString()),
        _buildCriterioRow(Icons.star_border_outlined, 'Orden General', reporte.ordenGeneral.toString()),
        _buildCriterioRow(Icons.school_outlined, 'Disciplina', reporte.disciplina.toString()),
        _buildCriterioRow(Icons.check_circle, 'Total Final', reporte.totalFinal.toString(), isTotal: true), // Cambiado 'Total' por 'Total Final'
      ],
    );
  }

  Widget _buildPhoneLayout(LimpiezaReporte reporte) {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      return SingleChildScrollView( 
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1, 
              child: _buildInfoCard(reporte),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1, 
              child: _buildCriteriaList(reporte),
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: () async => _obtenerDatos(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(reporte),
            const SizedBox(height: 16),
            _buildCriteriaList(reporte),
          ],
        ),
      );
    }
  }


  Widget _buildTabletLayout(LimpiezaReporte reporte) {
     return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildInfoCard(reporte)),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: _buildCriteriaList(reporte),
            ),
          ],
        ),
      );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildCriterioRow(IconData icon, String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: isTotal ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
