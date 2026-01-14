import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/Estudiantes/models/institutional_user.dart';

class UserProvider with ChangeNotifier {
  // --- CAMPOS PRIVADOS ---
  String _usuarioID = '';     // Matrícula (Estudiante/Monitor) o ClaveEmpleado (Preceptor)
  String _nombre = '';        // NombreCompleto
  int? _idRol;              // 1: Preceptor, 2: Monitor, 3: Estudiante (Nullable)
  
  // Datos específicos que pueden venir de la API (pueden ser null)
  String _carrera = '';       // Solo para estudiantes
  int? _idCuarto;         // ID del cuarto (estudiantes)
  int? _numeroCuarto;     // Número del cuarto (para mostrar en UI, viene del JOIN)
  int? _idPasillo;        // Para monitores (ahora está en Estudiantes)
  int? _idDormitorio;     // Para monitores y preceptores
  String _fotoUrl = '';       // URL de la foto de perfil (si la implementas)
  String _correoInstitucional = '';

  // --- GETTERS PÚBLICOS ---
  // Permiten leer los datos desde fuera de la clase de forma segura
  String get usuarioID => _usuarioID;
  String get nombre => _nombre;
  int? get idRol => _idRol;
  String get carrera => _carrera;
  int? get idCuarto => _idCuarto;
  int? get numeroCuarto => _numeroCuarto;
  int? get idPasillo => _idPasillo;
  int? get idDormitorio => _idDormitorio;
  String get fotoUrl => _fotoUrl; 
  String get correoInstitucional => _correoInstitucional;

  bool get isLoggedIn => _usuarioID.isNotEmpty && _idRol != null;
  String get matricula => _usuarioID; 

  void setUser(Map<String, dynamic> userData) {

    _usuarioID = userData['UsuarioID'] ?? '';
    _nombre = userData['NombreCompleto'] ?? '';
    _idRol = userData['IdRol']; 

    _carrera = userData['Carrera'] ?? '';
    _idCuarto = userData['IdCuarto']; 
    _numeroCuarto = userData['NumeroCuarto']; 
    _idPasillo = userData['IdPasillo']; 
    _idDormitorio = userData['IdDormitorio']; 
    _fotoUrl = userData['FotoUrl'] ?? ''; 
    _correoInstitucional = userData['Correo'] ?? '';
    notifyListeners();
  }

  // 4. METODO PARA ACTUALIZAR DESDE API UNI (Si lo estás usando en el Home)
  void updateFromInstitutionalUser(InstitutionalUser instUser) {
    if (instUser.nombre.isNotEmpty) {
       _nombre = '${instUser.nombre} ${instUser.apellidos}';
    }
    if (instUser.leNombreEscuelaOficial != null) {
       _carrera = instUser.leNombreEscuelaOficial!;
    }
    // Aquí actualizamos el correo con el dato fresco de la API
    _correoInstitucional = instUser.correoInstitucional;
    
    notifyListeners();
  }
  
  void logout() {
    _usuarioID = '';
    _nombre = '';
    _idRol = null;
    _carrera = '';
    _idCuarto = null;
    _numeroCuarto = null;
    _idPasillo = null;
    _idDormitorio = null;
    _fotoUrl = '';
    notifyListeners();
  }
}
