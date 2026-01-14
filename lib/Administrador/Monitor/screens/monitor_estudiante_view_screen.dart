import 'package:flutter/material.dart';
// 👇 Importamos TODAS las pantallas de Estudiante
import 'package:gestion_dormitorios/Estudiantes/screens/limpieza_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/asistencia_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/amonestaciones_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/reportes_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/estadisticas_screen.dart';

// Esta es la pantalla que muestra las opciones personales del monitor (como estudiante)
class MonitorEstudianteViewScreen extends StatelessWidget {
  const MonitorEstudianteViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Lista de opciones del estudiante
    final List<Map<String, dynamic>> opcionesEstudiante = [
      { 'icon': Icons.cleaning_services_outlined, 'color': Colors.teal, 'title': 'Mi Limpieza', 'screen': const LimpiezaScreen() },
      { 'icon': Icons.check_circle_outline, 'color': Colors.green, 'title': 'Mi Asistencia', 'screen': const AsistenciaScreen() },
      { 'icon': Icons.gavel_rounded, 'color': Colors.red.shade700, 'title': 'Mis Amonestaciones', 'screen': const AmonestacionesScreen() },
      { 'icon': Icons.description_outlined, 'color': Colors.orange.shade700, 'title': 'Mis Reportes', 'screen': const ReportesAlumnoScreen() },
      { 'icon': Icons.show_chart, 'color': Colors.purple, 'title': 'Mis Estadísticas', 'screen': const EstadisticasScreen() },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Vista Estudiante'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: aspectRatio,
              ),
              itemCount: opcionesEstudiante.length,
              itemBuilder: (context, index) {
                final opcion = opcionesEstudiante[index];
                // Usamos el mismo widget de tarjeta para consistencia
                return _buildMenuCard(
                  context: context,
                  icon: opcion['icon'],
                  color: opcion['color'],
                  title: opcion['title'],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => opcion['screen'])),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Copiamos el widget _buildMenuCard para mantener el mismo estilo visual
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