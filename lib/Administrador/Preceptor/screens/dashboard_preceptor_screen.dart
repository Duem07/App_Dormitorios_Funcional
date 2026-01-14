import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/theme_provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/monitores_preceptor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/reportes_preceptor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/limpieza_preceptor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/estadisticas_preceptor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/amonestaciones_preceptor_screen.dart'; 
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/AsignarCuartoScreen.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/VerOcupacionScreen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/configuracio_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/perfil_screen.dart'; 
import 'package:gestion_dormitorios/foto_perfil_widget.dart';

class DashboardPreceptorScreen extends StatefulWidget {
  const DashboardPreceptorScreen({super.key});

  @override
  State<DashboardPreceptorScreen> createState() =>
      _DashboardPreceptorScreenState();
}

class _DashboardPreceptorScreenState extends State<DashboardPreceptorScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = Provider.of<UserProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, isDark, user),
      appBar: AppBar(
        title: const Text('Panel del Preceptor'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        titleTextStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                        user.nombre.isNotEmpty ? user.nombre : 'Preceptor',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Administrador del HVU',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Secciones principales',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // --- CUADRÍCULA ADAPTABLE ---
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
                     { 'icon': Icons.bedroom_parent_outlined, 'color': Colors.cyan.shade700, 'title': 'Asignar Cuartos', 'screen': const AsignarCuartoScreen() },
                     { 'icon': Icons.grid_view_rounded, 'color': Colors.deepPurple, 'title': 'Ver Ocupación','screen': const VerOcupacionScreen() },
                     { 'icon': Icons.people_alt_outlined, 'color': Colors.indigo, 'title': 'Monitores', 'screen': const MonitoresScreen() },
                     { 'icon': Icons.report_outlined, 'color': Colors.orange.shade700, 'title': 'Reportes', 'screen': const ReportesPreceptorScreen() },
                     { 'icon': Icons.gavel_rounded, 'color': Colors.red.shade700, 'title': 'Amonestaciones', 'screen': const AmonestacionesPreceptorScreen() },
                     { 'icon': Icons.cleaning_services_outlined, 'color': Colors.teal, 'title': 'Limpieza', 'screen': const LimpiezaPreceptorScreen() },
                     { 'icon': Icons.bar_chart_outlined, 'color': Colors.purple, 'title': 'Estadísticas', 'screen': const EstadisticasPreceptorScreen() },
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
                       return _buildOptionCard(
                        context,
                        icon: opcion['icon'],
                        color: opcion['color'],
                        title: opcion['title'],
                        onTap: () => _goTo(context, opcion['screen']),
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

  // --- Widget para la tarjeta de opción ---
  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    // ... (este widget no necesita cambios)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor, // Usamos el color de tarjeta del tema
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // Sombra más sutil
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12), // Padding interno
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color), // Usamos el color pasado para el icono
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center, // Centramos por si el título es largo
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAWER IZQUIERDO ---
  Drawer _buildDrawer(BuildContext context, bool isDark, UserProvider user) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor, 
      child: Column( 
        children: [
          UserAccountsDrawerHeader(
             decoration: BoxDecoration(
               color: theme.colorScheme.primary, 
             ),
             accountName: Text(
               user.nombre.isNotEmpty ? user.nombre : 'Preceptor', // Nombre real
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
             ),
             accountEmail: Text(user.usuarioID), 
             currentAccountPicture: 
              FotoPerfilWidget(
                matricula: user.usuarioID, // El preceptor usa su clave de empleado
                size: 30,
              ),
           ),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context); // Cerramos drawer
              _goTo(context, const PerfilScreen()); // Reutilizamos PerfilScreen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context); // Cerramos drawer
              _goTo(context, const ConfiguracionScreen());
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
    );
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
} 

