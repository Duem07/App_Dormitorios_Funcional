import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/services/auth_service.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  final String? correoInicial; // Opcional, si viene del perfil ya lo sabemos
  const RecuperarPasswordScreen({super.key, this.correoInicial});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _authService = AuthService();
  
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  int _step = 0; // 0:Correo, 1:Código, 2:Nueva Pass
  bool _isLoading = false;

  // 1. VARIABLES INDEPENDIENTES PARA CADA CAMPO
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.correoInicial != null) {
      emailCtrl.text = widget.correoInicial!;
    }
  }

  void _sendCode() async {
    if (emailCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    // 1. Enviar OTP
    final enviado = await _authService.sendOtpToEmail(emailCtrl.text.trim());
    
    setState(() => _isLoading = false);
    if (enviado) {
      setState(() => _step = 1);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código enviado a tu correo')));
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar código. Verifica el correo.')));
    }
  }

  void _verifyCode() async {
    if (codeCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    // 2. Verificar OTP
    final valido = await _authService.verifyOtpCode(emailCtrl.text.trim(), codeCtrl.text.trim());

    setState(() => _isLoading = false);
    if (valido) {
      setState(() => _step = 2); // Pasar a cambio de contraseña
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código incorrecto')));
    }
  }

  void _changePassword() async {
    if (passCtrl.text.isEmpty || passCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden o están vacías')));
      return;
    }
    setState(() => _isLoading = true);

    // 3. Guardar nueva contraseña
    final exito = await _authService.resetPassword(emailCtrl.text.trim(), passCtrl.text.trim());

    setState(() => _isLoading = false);
    if (exito) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Contraseña actualizada!')));
        Navigator.pop(context); // Regresar
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar contraseña')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: // Pedir Correo
        return Column(
          children: [
            const Text('Ingresa tu correo institucional para recibir un código.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl, 
              decoration: const InputDecoration(
                labelText: 'Correo', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined)
              )
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _sendCode, child: const Text('Enviar Código'))
            )
          ],
        );

      case 1: // Pedir Código
        return Column(
          children: [
            Text('Código enviado a ${emailCtrl.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: codeCtrl, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código OTP', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_clock_outlined)
              )
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _verifyCode, child: const Text('Verificar'))
            )
          ],
        );

      case 2: // Nueva Contraseña (AQUÍ ESTÁN LOS CAMBIOS DEL OJITO)
        return Column(
          children: [
            const Text('Crea tu nueva contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // CAMPO 1: NUEVA CONTRASEÑA
            TextField(
              controller: passCtrl, 
              obscureText: _obscurePass, // Variable 1
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña', 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                // Botón del ojo
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePass = !_obscurePass;
                    });
                  },
                ),
              )
            ),
            const SizedBox(height: 15),

            // CAMPO 2: CONFIRMAR CONTRASEÑA
            TextField(
              controller: confirmPassCtrl, 
              obscureText: _obscureConfirm, // Variable 2
              decoration: InputDecoration(
                labelText: 'Confirmar', 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                // Botón del ojo
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              )
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _changePassword, child: const Text('Actualizar Contraseña'))
            )
          ],
        );
      default: return Container();
    }
  }
}