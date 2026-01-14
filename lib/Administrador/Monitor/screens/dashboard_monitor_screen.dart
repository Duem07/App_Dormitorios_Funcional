import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/theme_provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/generar_qr_monitor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/asistencias_monitor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/limpieza_monitor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/reportes_monitor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/estadisticas_monitor_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/configuracio_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/perfil_screen.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/monitor_estudiante_view_screen.dart';
import 'package:gestion_dormitorios/foto_perfil_widget.dart';


class DashboardMonitorScreen extends StatelessWidget {
  const DashboardMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.iconTheme.color),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Panel del Monitor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        centerTitle: true,
      ),

      drawer: Drawer(
        backgroundColor: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FotoPerfilWidget(
                    matricula: user.usuarioID, // En monitor solemos usar usuarioID o matricula
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.nombre.isNotEmpty ? user.nombre : 'Monitor',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Monitor del HVU - ${user.usuarioID}', // Mostramos ID/Matrícula
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
             // --- Opción de Perfil ---
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context); // Cerramos drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                 Navigator.pop(context); // Cerramos drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Provider.of<UserProvider>(context, listen: false).logout();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FotoPerfilWidget(
                  matricula: user.usuarioID,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nombre.isNotEmpty ? '${user.nombre} (Monitor)' : 'Monitor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ), 
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 30),

            // --- Cuadrícula Adaptable ---
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  int crossAxisCount;
                  double aspectRatio = 1.0;

                  if (width > 900) {
                    crossAxisCount = 4;
                    aspectRatio = 1.1;
                  } else if (width > 600) {
                    crossAxisCount = 3;
                    aspectRatio = 1.0;
                  } else {
                    crossAxisCount = 2;
                    aspectRatio = 0.95;
                  }

                  final List<Map<String, dynamic>> opciones = [
                     { 'icon': Icons.qr_code_2, 'color': Colors.blueGrey, 'title': 'Generar QR', 'screen': const GenerarQRMonitorScreen() },
                     { 'icon': Icons.people_alt_outlined, 'color': Colors.lightBlue, 'title': 'Ver Asistencias', 'screen': const AsistenciasMonitorScreen() },
                     { 'icon': Icons.cleaning_services_rounded, 'color': Colors.teal, 'title': 'Limpieza', 'screen': const LimpiezaMonitorScreen() },
                     { 'icon': Icons.report_problem_outlined, 'color': Colors.orange, 'title': 'Reportes', 'screen': const ReportesMonitorScreen() },
                     { 'icon': Icons.bar_chart_outlined, 'color': Colors.purple, 'title': 'Estadísticas', 'screen': const EstadisticasMonitorScreen() },
                     { 'icon': Icons.school_outlined, 'color': Colors.green.shade600, 'title': 'Vista Estudiante', 'screen': const MonitorEstudianteViewScreen() },
                  ];

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: opciones.length,
                    itemBuilder: (context, index) {
                      final opcion = opciones[index];
                       return _buildMenuCard(
                        context: context,
                        icon: opcion['icon'],
                        color: opcion['color'],
                        title: opcion['title'],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => opcion['screen'])),
                      );
                    }
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

