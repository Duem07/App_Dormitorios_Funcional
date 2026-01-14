class InstitutionalUser {
  final int? matricula;
  final String nombre;
  final String apellidos;
  final String correoInstitucional;
  final String? residencia;
  final String? nivelEducativo;
  final String? campo; // Campus
  final String? leNombreEscuelaOficial; // Carrera o Departamento
  final String? sexo;
  final int? numEmpleado;
  final String? direccion;

  InstitutionalUser({
    this.matricula,
    required this.nombre,
    required this.apellidos,
    required this.correoInstitucional,
    this.residencia,
    this.nivelEducativo,
    this.campo,
    this.leNombreEscuelaOficial,
    this.sexo,
    this.numEmpleado,
    this.direccion,
  });

  factory InstitutionalUser.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> dataReal = {};
    bool esEmpleado = false;

    final rootData = json['Data'] ?? json['data'];

    if (rootData != null) {
    
      // A) Caso ALUMNO ("student")
      if (rootData is Map && rootData.containsKey('student') && 
          rootData['student'] is List && 
          (rootData['student'] as List).isNotEmpty) {
        dataReal = rootData['student'][0];
      } 
      // B) Caso EMPLEADO ("employee")
      else if (rootData is Map && rootData.containsKey('employee') && 
               rootData['employee'] is List && 
               (rootData['employee'] as List).isNotEmpty) {
        dataReal = rootData['employee'][0];
        esEmpleado = true;
      }
      // C) Caso de emergencia (si viene plano)
      else if (rootData is Map) {
       dataReal = Map<String, dynamic>.from(rootData);
      }
    } else {
      dataReal = json;
    }

    // --- FUNCIONES AUXILIARES ---
    String? cleanString(dynamic value) {
      if (value == null || value.toString() == 'null' || value.toString().trim().isEmpty) {
        return null;
      }
      return value.toString();
    }

    int? parseInt(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return int.tryParse(value.toString());
    }

    // --- 3. MAPEO DE CAMPOS (Manejando variaciones) ---

    final idValor = parseInt(dataReal['MATRICULA'] ?? dataReal['matricula']);

    return InstitutionalUser(
      matricula: esEmpleado ? null : idValor,
      
      numEmpleado: esEmpleado ? idValor : null,

      nombre: cleanString(dataReal['NOMBRES'] ?? dataReal['NOMBRE']) ?? 'Sin Nombre',
      apellidos: cleanString(dataReal['APELLIDOS'] ?? dataReal['APELLIDOS_TUTOR']) ?? 'Sin Apellidos',

      correoInstitucional: cleanString(
        dataReal['CORREO_INSTITUCIONAL'] ?? 
        dataReal['EMAIl_INSTITUCIONAL'] ?? 
        dataReal['EMAIL_INSTITUCIONAL'] ??
        dataReal['email_institucional']
      ) ?? '',
      
      residencia: cleanString(dataReal['RESIDENCIA']),
      nivelEducativo: cleanString(dataReal['NIVEL_EDUCATIVO']),
      campo: cleanString(dataReal['CAMPO'] ?? dataReal['CAMPUS']),
      leNombreEscuelaOficial: cleanString(
        dataReal['LeNombreEscuelaOficial'] ?? 
        dataReal['DEPARTAMENTO'] ?? 
        dataReal['PUESTO']
      ),
      
      sexo: cleanString(dataReal['SEXO']),
      direccion: cleanString(dataReal['DIRECCION']),
    );
  }

  String get correoOculto {
    if (correoInstitucional.isEmpty || !correoInstitucional.contains('@')) {
      return 'No disponible';
    }
    final parts = correoInstitucional.split('@');
    final user = parts[0];
    final domain = parts[1];
    
    if (user.length <= 3) return '${user[0]}***@$domain';
    return '${user.substring(0, 3)}***@$domain';
  }
}