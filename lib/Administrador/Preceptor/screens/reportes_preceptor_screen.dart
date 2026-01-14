import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/services/reporte_service.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/reporte_monitor_model.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/crear_reporte_preceptor_screen.dart';
import 'dart:async'; 

class ReportesPreceptorScreen extends StatefulWidget {
  const ReportesPreceptorScreen({super.key});

  @override
  State<ReportesPreceptorScreen> createState() => _ReportesPreceptorScreenState();
}

class _ReportesPreceptorScreenState extends State<ReportesPreceptorScreen> {
  final ReporteService _reporteService = ReporteService();
  List<ReporteMonitor> _reportes = [];
  bool _isLoading = true; // Para la carga inicial
  bool _isLoadingMore = false; // Para la carga de scroll infinito
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _limit = 20;
  int _totalReportes = 0;
  bool _isLastPage = false;
  final ScrollController _scrollController = ScrollController(); 

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; 

  // --- NUEVO ESTADO: Para manejar la actualización de un item específico ---
  bool _isUpdatingReporte = false;
  int? _updatingReporteId; // Almacena el ID del reporte que se está actualizando

  @override
  void initState() {
    super.initState();
    _cargarReportesIniciales(); 

    _scrollController.addListener(() {
      // Condición para cargar más:
      // 1. Llegar casi al final del scroll
      // 2. No estar ya en una carga inicial (_isLoading)
      // 3. No estar cargando más (_isLoadingMore)
      // 4. No ser la última página (_isLastPage)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading && !_isLoadingMore && !_isLastPage) {
        _cargarMasReportes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Carga la primera página de reportes o los resultados de una nueva búsqueda.
  Future<void> _cargarReportesIniciales({String? searchTerm}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Carga inicial
      _hasError = false;
      _currentPage = 1; 
      _isLastPage = false;
      _reportes = [];
    });

    try {
      final resultado = await _reporteService.getAllReportes(
        page: _currentPage,
        limit: _limit,
        search: searchTerm, 
      );
      if (!mounted) return;
      setState(() {
        _reportes = resultado['reportes'] as List<ReporteMonitor>;
        _totalReportes = resultado['total'] as int;
        _isLastPage = _reportes.length >= _totalReportes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Carga la siguiente página de reportes (para scroll infinito).
  Future<void> _cargarMasReportes() async {
    if (_isLoading || _isLoadingMore || _isLastPage || !mounted) return; 

    setState(() => _isLoadingMore = true); // Usamos el loader de "cargar más"
    _currentPage++;

    try {
       final resultado = await _reporteService.getAllReportes(
        page: _currentPage,
        limit: _limit,
        search: _searchController.text.trim(), 
      );
       if (!mounted) return;
       setState(() {
         _reportes.addAll(resultado['reportes'] as List<ReporteMonitor>); // Añade los nuevos a la lista
         _totalReportes = resultado['total'] as int; // Actualiza total por si acaso
         _isLastPage = _reportes.length >= _totalReportes;
       });
    } catch (e) {
       if (!mounted) return;
       setState(() {
         _errorMessage = "Error al cargar más: $e";
         _currentPage--; // Revertimos la página si falla
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red));
       });
    } finally {
       if (mounted) {
        setState(() => _isLoadingMore = false); // Ocultamos el loader de "cargar más"
       }
    }
  }

  /// Búsqueda con debounce (sin cambios)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _cargarReportesIniciales(searchTerm: query.trim());
    });
  }

  /// Navegación para crear reporte (sin cambios)
  void _irACrearReportePreceptor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearReportePreceptorScreen()), 
    ).then((seGuardo) {
      if (seGuardo == true && mounted) {
        _cargarReportesIniciales(searchTerm: _searchController.text.trim());
      }
    });
  }

  // --- 👇 NUEVA FUNCIÓN: Aprobar Reporte ---
  Future<void> _aprobarReporte(ReporteMonitor reporte) async {
    if (_isUpdatingReporte) return; // Evitar doble tap

    final preceptorId = Provider.of<UserProvider>(context, listen: false).usuarioID;
    if (preceptorId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se pudo identificar al preceptor.'), backgroundColor: Colors.red));
       return;
    }

    setState(() {
      _isUpdatingReporte = true;
      _updatingReporteId = reporte.idReporte; // Marcamos esta tarjeta como "cargando"
    });

    try {
      final resultado = await _reporteService.aprobarReporte(reporte.idReporte, preceptorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'Reporte aprobado.'), backgroundColor: Colors.green)
      );
      // Recargamos toda la lista para que se actualice el estado
      _cargarReportesIniciales(searchTerm: _searchController.text.trim());

    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error al aprobar: $e'), backgroundColor: Colors.red)
       );
    } finally {
       if (mounted) {
         setState(() {
           _isUpdatingReporte = false;
           _updatingReporteId = null;
         });
       }
    }
  }

  // --- 👇 NUEVA FUNCIÓN: Rechazar Reporte ---
  Future<void> _rechazarReporte(ReporteMonitor reporte) async {
     if (_isUpdatingReporte) return; // Evitar doble tap

    // Pedimos confirmación antes de rechazar
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Rechazo'),
        content: Text('¿Estás seguro de RECHAZAR este reporte? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return; // Si no confirma, no hacer nada

    setState(() {
      _isUpdatingReporte = true;
      _updatingReporteId = reporte.idReporte;
    });

     try {
      final resultado = await _reporteService.rechazarReporte(reporte.idReporte);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'Reporte rechazado.'), backgroundColor: Colors.blue) // Color azul para info
      );
      // Recargamos la lista para que se actualice el estado
      _cargarReportesIniciales(searchTerm: _searchController.text.trim());

    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error al rechazar: $e'), backgroundColor: Colors.red)
       );
    } finally {
       if (mounted) {
         setState(() {
           _isUpdatingReporte = false;
           _updatingReporteId = null;
         });
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Reportes (HVU)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Campo de Búsqueda ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Matrícula o Nombre',
                hintText: 'Escribe para buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged(''); 
                      },
                    )
                  : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // --- Lista de Reportes ---
          Expanded(
            child: _buildBodyContent(theme), // Usamos una función auxiliar para el contenido
          ),
        ],
      ),
      // --- Botón Flotante ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irACrearReportePreceptor,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Reporte'),
        tooltip: 'Crear un nuevo reporte para un estudiante',
      ),
    );
  }

  /// Widget que construye el contenido del body (loading, error, lista)
  Widget _buildBodyContent(ThemeData theme){
     // Estado de Carga inicial (solo muestra si la lista está vacía)
      if (_isLoading && _reportes.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      // Estado de Error al cargar inicial
      if (_hasError && _reportes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Error al cargar los reportes:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        );
      }
      // Estado Sin Datos (lista vacía)
      if (_reportes.isEmpty) {
        return Center(
          child: Text(
             _searchController.text.isNotEmpty
               ? 'No se encontraron reportes para "${_searchController.text}".'
               : 'No hay reportes registrados en el sistema.',
            textAlign: TextAlign.center,
          ),
        );
      }

      // --- Muestra la Lista ---
      return RefreshIndicator( 
         onRefresh: () async => _cargarReportesIniciales(searchTerm: _searchController.text.trim()),
        child: ListView.builder(
          controller: _scrollController, 
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), 
          // Sumamos 1 si estamos cargando más (para mostrar el indicador al final)
          itemCount: _reportes.length + (_isLoadingMore ? 1 : 0), 
          itemBuilder: (context, index) {
            
            // --- Indicador de Carga al final de la lista ---
            if (index == _reportes.length) {
              return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Container(); // Si es la última página, no muestra nada
            }
            
            // --- Muestra la tarjeta del reporte ---
            return _buildReporteCard(context, _reportes[index]);
          },
        ),
      );
  }


  /// Widget para mostrar la tarjeta de un reporte (ACTUALIZADO CON ESTADOS Y BOTONES)
  Widget _buildReporteCard(BuildContext context, ReporteMonitor reporte) {
    final theme = Theme.of(context);
    // 👇 Obtenemos colores e iconos dinámicamente según el estado
    final Color colorEstado = _colorEstado(reporte.estado);
    final IconData iconoEstado = _iconoEstado(reporte.estado);
    // Verificamos si esta tarjeta específica está actualizándose
    final bool isUpdatingThisCard = _isUpdatingReporte && _updatingReporteId == reporte.idReporte;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudiante: ${reporte.nombreEstudianteReportado}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if(reporte.matriculaReportado != null)
              Text(
                'Matrícula: ${reporte.matriculaReportado}',
                style: theme.textTheme.bodySmall,
              ),
            const Divider(height: 16),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(reporte.fechaReporte)}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Motivo: ${reporte.motivo}'),
            const SizedBox(height: 8),
            Text(
              'Reportado por: ${reporte.reportadoPorNombre} (${reporte.tipoUsuarioReportante ?? 'N/A'})',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            
            // --- Estado del Reporte (Dinámico) ---
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconoEstado, size: 16, color: colorEstado),
                    const SizedBox(width: 6),
                    Text(
                      reporte.estado, // Muestra el estado real
                      style: TextStyle(color: colorEstado, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // --- 👇 SECCIÓN DE ACCIONES (SOLO SI ESTÁ PENDIENTE) ---
            if (reporte.estado.toLowerCase() == 'pendiente')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: isUpdatingThisCard // Si esta tarjeta se está actualizando
                  ? const Center(child: CircularProgressIndicator()) // Muestra loading
                  : Row( // Si no, muestra botones
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rechazar'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () => _rechazarReporte(reporte), // Llama a la función de rechazar
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _aprobarReporte(reporte), // Llama a la función de aprobar
                        ),
                      ],
                    ),
              ),
          ],
        ),
      ),
    );
  }

  // --- 👇 NUEVAS FUNCIONES AUXILIARES DE ESTILO (MANEJAN 3 ESTADOS) ---
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado': return Colors.green.shade700;
      case 'pendiente': return Colors.orange.shade700;
      case 'rechazado': return Colors.red.shade700;
      default: return Colors.grey.shade600;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado': return Icons.check_circle_outline;
      case 'pendiente': return Icons.hourglass_empty_rounded;
      case 'rechazado': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }
}