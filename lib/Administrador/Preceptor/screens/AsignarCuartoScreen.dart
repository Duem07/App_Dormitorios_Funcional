import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/dormitorio_service.dart';

class AsignarCuartoScreen extends StatefulWidget {
  const AsignarCuartoScreen({super.key});

  @override
  State<AsignarCuartoScreen> createState() => _AsignarCuartoScreenState();
}

class _AsignarCuartoScreenState extends State<AsignarCuartoScreen> {
  final DormitorioService _service = DormitorioService();
  
  // Listas de datos
  List<dynamic> _estudiantes = [];
  List<dynamic> _dormitorios = [];
  List<dynamic> _pasillos = [];
  List<dynamic> _cuartos = [];

  // Selecciones
  String? _matriculaSeleccionada;
  int? _dormitorioSeleccionado;
  int? _pasilloSeleccionado;
  int? _cuartoSeleccionado;

  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

 void _cargarDatosIniciales() async {
    try {
      final estudiantes = await _service.getEstudiantesParaAsignacion();
      final pasillos = await _service.getPasillos();
      final dormitorios = await _service.getDormitorios();
      
      print('Estudiantes cargados: ${estudiantes.length}'); // DEBUG
      print('Pasillos cargados: ${pasillos.length}');   
          // DEBUG

      if (mounted) {
        setState(() {
          _estudiantes = estudiantes;
          _pasillos = pasillos;
          _dormitorios = dormitorios;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR CARGANDO DATOS: $e'); // <--- ESTO ES CRUCIAL
      if (mounted) {
        setState(() => _isLoading = false);
        // Mostrar error en pantalla para que lo veas
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _cargarCuartos(int idPasillo) async {
    setState(() {
      _cuartoSeleccionado = null; // Reset cuarto al cambiar pasillo
      _cuartos = []; // Limpiar lista anterior
    });
    
    final cuartos = await _service.getCuartosPorPasillo(idPasillo);
    if (mounted) {
      setState(() => _cuartos = cuartos);
    }
  }

 void _guardar() async {
    if (_matriculaSeleccionada == null || _dormitorioSeleccionado == null || _pasilloSeleccionado == null || _cuartoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona todos los campos')));
      return;
    }

    setState(() => _saving = true);
    
    final exito = await _service.asignarCuarto(
      _matriculaSeleccionada!, 
      _dormitorioSeleccionado!,
      _pasilloSeleccionado!, 
      _cuartoSeleccionado!);

    setState(() => _saving = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignación exitosa'), backgroundColor: Colors.green));
      _cargarDatosIniciales(); // Recargar para quitar al estudiante de la lista
      
      // Reseteamos campos
      setState(() {
        _matriculaSeleccionada = null;
        _pasilloSeleccionado = null;
        _cuartoSeleccionado = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al asignar'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Cuarto')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. Selecciona Estudiante:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _matriculaSeleccionada,
                  hint: const Text('Buscar estudiante...'),
                  isExpanded: true,
                  items: _estudiantes.map((e) {
                    return DropdownMenuItem<String>(
                      value: e['Matricula'].toString(),
                      child: Text('${e['Matricula']} - ${e['NombreCompleto']}'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _matriculaSeleccionada = val),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                
                // 2. NUEVO: DORMITORIO
                const Text('2. Selecciona Dormitorio:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _dormitorioSeleccionado,
                  hint: const Text('Seleccionar edificio'),
                  items: _dormitorios.map((d) {
                    return DropdownMenuItem<int>(
                      value: d['IdDormitorio'],
                      // AQUÍ MOSTRAMOS EL NOMBRE (Ej. "HVU")
                      child: Text(d['NombreDormitorio'] ?? 'Edificio ${d['IdDormitorio']}'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _dormitorioSeleccionado = val),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),

                const SizedBox(height: 20),
                const Text('3. Selecciona Pasillo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _pasilloSeleccionado,
                  hint: const Text('Seleccionar pasillo'),
                  items: _pasillos.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['IdPasillo'],
                      child: Text(p['NombrePasillo'] ?? 'Pasillo ${p['IdPasillo']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _pasilloSeleccionado = val);
                    if (val != null) _cargarCuartos(val); // Cargar cuartos dependientes
                  },
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),

                const SizedBox(height: 20),
                const Text('4. Selecciona Cuarto:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _cuartoSeleccionado,
                  hint: Text(_pasilloSeleccionado == null ? 'Primero elige pasillo' : 'Seleccionar cuarto'),
                  disabledHint: const Text('Primero elige pasillo'),
                  items: _cuartos.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['IdCuarto'],
                      child: Text('Cuarto ${c['NumeroCuarto']} (Cap: ${c['Capacidad']})'),
                    );
                  }).toList(),
                  onChanged: _pasilloSeleccionado == null ? null : (val) => setState(() => _cuartoSeleccionado = val),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),

                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _guardar,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                    child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR ASIGNACIÓN'),
                  ),
                )
              ],
            ),
          ),
    );
  }
}