import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/recuperar_password_screen.dart';
import 'package:provider/provider.dart'; 
import 'package:gestion_dormitorios/providers/user_provider.dart'; 
import 'package:gestion_dormitorios/foto_perfil_widget.dart'; // Asegúrate de la ruta correcta

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: const Text('Perfil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          _buildUserProfileHeader(context, isDark, user),
          const SizedBox(height: 12),
          _buildProfileOption(
            context: context,
            icon: Icons.lock_outline,
            text: 'Cambiar contraseña',
            isDark: isDark,
            onTap: () {
              final correo = user.correoInstitucional;
              if(correo.isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No tienes un correo registrado para recuperar la contraseña'))
                );
                return;
              }
            
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => RecuperarPasswordScreen(correoInicial: correo)
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(BuildContext context, bool isDark, UserProvider user) {
    final theme = Theme.of(context);

    // Variables dinámicas según el rol
    String? subTitulo1; // Usualmente el Rol o Carrera
    String? subTitulo2; // Información extra (Dormitorio, Pasillo, Cuarto)
    String? textoDebajoNombre; // Lo que va justo debajo del nombre (antes era la matrícula)
    
    IconData? icon1;
    IconData? icon2;

    switch (user.idRol) { 
      case 1: // Preceptor
        textoDebajoNombre = null; // Ocultamos el número de empleado
        subTitulo1 = 'Rol: Preceptor';
        icon1 = Icons.supervisor_account_outlined;
        
        // Mostramos el nombre del dormitorio si existe, si no, uno genérico
        // Asumiendo que user.idDormitorio guarda el ID, podrías mapearlo a nombre si tienes la info,
        // o poner el nombre fijo si este preceptor siempre es del HVU.
        // Aquí pongo un texto fijo bonito como pediste:
        subTitulo2 = 'Administrador: Hogar de Varones Universitarios'; 
        icon2 = Icons.business_outlined;
        break;

      case 2: // Monitor
        textoDebajoNombre = null; // Ocultamos la matrícula
        subTitulo1 = 'Rol: Monitor';
        icon1 = Icons.support_agent_outlined;
        if (user.idPasillo != null) {
           subTitulo2 = 'Encargado del Pasillo: ${user.idPasillo}';
           icon2 = Icons.meeting_room_outlined;
        }
        break;

      case 3: // Estudiante
      default: 
        textoDebajoNombre = user.matricula; // Al estudiante SÍ le mostramos su matrícula
        subTitulo1 = user.carrera.isNotEmpty ? user.carrera : 'Estudiante'; 
        icon1 = Icons.school_outlined;
        
        if (user.numeroCuarto != null) { 
           subTitulo2 = 'Cuarto Asignado: ${user.numeroCuarto}';
           icon2 = Icons.bed_outlined;
        } else {
           subTitulo2 = 'Cuarto: Sin asignar';
           icon2 = Icons.bed_outlined;
        }
        break;
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        // FOTO DE PERFIL
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              FotoPerfilWidget(
                matricula: user.usuarioID.isNotEmpty ? user.usuarioID : user.matricula, 
                size: 60, 
              ),
              // El botón de cámara es decorativo por ahora, a menos que tengas lógica para subir foto
              InkWell(
                onTap: () { },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // NOMBRE DEL USUARIO
        Text(
          user.nombre.isNotEmpty ? user.nombre : 'Usuario',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // TEXTO DEBAJO DEL NOMBRE (Matrícula solo para estudiante)
        if (textoDebajoNombre != null)
          Text(
            textoDebajoNombre, 
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 16), 

        // TARJETAS DE INFORMACIÓN (Rol, Dormitorio, Cuarto)
        if (subTitulo1 != null)
           _buildInfoRow(context, icon1 ?? Icons.info_outline, subTitulo1),
        
        if (subTitulo2 != null)
           _buildInfoRow(context, icon2 ?? Icons.info_outline, subTitulo2),

      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
     final theme = Theme.of(context);
     return Container(
       margin: const EdgeInsets.symmetric(vertical: 4.0),
       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
       decoration: BoxDecoration(
         color: theme.cardColor,
         borderRadius: BorderRadius.circular(8),
         // Sutil borde o sombra si quieres
         border: Border.all(color: Colors.grey.withOpacity(0.1))
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center, 
         mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
         children: [
           Icon(icon, size: 20, color: theme.colorScheme.primary),
           const SizedBox(width: 10),
           Flexible(
             child: Text(
               text, 
               style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500), 
               textAlign: TextAlign.center,
             )
           ), 
         ],
       ),
     );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final iconColor = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}