import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/usuario_service.dart'; 
import 'package:gestion_dormitorios/Administrador/Preceptor/models/monitor_info_model.dart'; 

class MonitoresScreen extends StatefulWidget {
  const MonitoresScreen({super.key});

  @override
  State<MonitoresScreen> createState() => _MonitoresScreenState();
}

class _MonitoresScreenState extends State<MonitoresScreen> {
  final TextEditingController _matriculaController = TextEditingController();
  final UsuarioService _usuarioService = UsuarioService();

  late Future<List<MonitorInfo>> _futureMonitores;
  bool _isAssigning = false; 
  bool _isRemoving = false; 
  String? _removingMonitorId; 

  @override
  void initState() {
    super.initState();
    _cargarMonitores(); 
  }

  void _cargarMonitores() {
    if (!mounted) return; 
    setState(() {
      _futureMonitores = _usuarioService.getMonitores();
    });
  }

  Future<void> _asignarMonitor() async {
    final matricula = _matriculaController.text.trim();
    if (matricula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la matrícula del estudiante.'), backgroundColor: Colors.orange),
      );
      return;
    }

    FocusScope.of(context).unfocus(); 
    if (!mounted) return;
    setState(() => _isAssigning = true);

    try {
      // Llama al servicio para asignar el rol (cambiar IdRol a 2)
      final resultado = await _usuarioService.asignarMonitor(matricula);
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'Monitor asignado correctamente'), backgroundColor: Colors.green),
      );
      _matriculaController.clear(); // Limpiamos el campo de texto
      _cargarMonitores(); // Recargamos la lista para mostrar el nuevo monitor
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar rol: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false); // Oculta indicador de carga
      }
    }
  }

  /// Intenta quitar el rol de monitor (cambiar IdRol a 3)
  Future<void> _quitarMonitor(String matricula, String nombre) async {
    // Mostramos un diálogo de confirmación antes de proceder
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Acción'),
        content: Text('¿Estás seguro de quitar el rol de monitor a $nombre ($matricula)? El usuario volverá a ser un estudiante regular.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No confirmar
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Sí confirmar
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar Rol'),
          ),
        ],
      ),
    );

    // Si el preceptor no confirma, salimos de la función
    if (confirm != true) return;

    if (!mounted) return;
    setState(() {
      _isRemoving = true; // Muestra indicador de carga en el botón de eliminar
      _removingMonitorId = matricula; // Guardamos qué monitor se está procesando
    });

    try {
      // Llama al servicio para quitar el rol (cambiar IdRol a 3)
      final resultado = await _usuarioService.quitarMonitor(matricula);
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'Rol de monitor quitado'), backgroundColor: Colors.green),
      );
      _cargarMonitores(); // Recargamos la lista para reflejar el cambio
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al quitar rol: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false; // Oculta indicador de carga
          _removingMonitorId = null; // Limpia la marca del monitor procesado
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Monitores'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lista de Monitores Actuales',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // --- LISTA DE MONITORES (CONECTADA A LA API) ---
            Expanded(
              // Usamos RefreshIndicator para permitir recargar la lista
              child: RefreshIndicator(
                onRefresh: () async => _cargarMonitores(),
                child: FutureBuilder<List<MonitorInfo>>(
                  future: _futureMonitores, // El Future que carga los datos
                  builder: (context, snapshot) {
                    // Muestra indicador mientras carga
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Muestra error si falla la carga
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar monitores: ${snapshot.error}',
                           style: TextStyle(color: theme.colorScheme.error),
                           textAlign: TextAlign.center,
                        )
                      );
                    }
                    // Muestra mensaje si no hay monitores
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay monitores asignados actualmente. Puedes asignar uno abajo.'));
                    }

                    // Si hay datos, muestra la lista
                    final monitores = snapshot.data!;
                    return ListView.builder(
                      itemCount: monitores.length,
                      itemBuilder: (context, index) {
                        final monitor = monitores[index];
                        // Verifica si este monitor es el que se está eliminando
                        final isBeingRemoved = _isRemoving && _removingMonitorId == monitor.usuarioID;
                        
                        return Card(
                          color: theme.cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar( // Avatar con inicial o icono
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                monitor.nombreCompleto.isNotEmpty ? monitor.nombreCompleto[0] : '?',
                                style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                              )
                              // child: Icon(Icons.person_outline, color: theme.colorScheme.onPrimaryContainer),
                            ),
                            title: Text(monitor.nombreCompleto),
                            subtitle: Text('Matrícula: ${monitor.usuarioID}'),
                            // Muestra indicador si se está eliminando, sino el botón
                            trailing: isBeingRemoved
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : IconButton(
                                  icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                                  tooltip: 'Quitar rol de monitor',
                                  // Deshabilita si ya se está procesando una eliminación
                                  onPressed: _isRemoving ? null : () => _quitarMonitor(monitor.usuarioID, monitor.nombreCompleto),
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
             const SizedBox(height: 20),

             Text('Asignar Nuevo Monitor',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
            TextField(
              controller: _matriculaController,
              decoration: InputDecoration(
                labelText: 'Matrícula del Estudiante',
                hintText: 'Ingresa la matrícula a asignar como monitor',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              keyboardType: TextInputType.number, // Teclado numérico
              textInputAction: TextInputAction.done, // Botón listo en teclado
            ),
            const SizedBox(height: 12),

            // --- Botón Agregar ---
            ElevatedButton.icon(
              onPressed: _isAssigning ? null : _asignarMonitor, // Deshabilitar si está cargando
              icon: _isAssigning
                ? Container( // Indicador de carga dentro del botón
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary, // Color del indicador
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1_outlined),
              label: Text(_isAssigning ? 'Asignando...' : 'Asignar Rol de Monitor'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Botón ancho
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordes redondeados
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    super.dispose();
  }
}

