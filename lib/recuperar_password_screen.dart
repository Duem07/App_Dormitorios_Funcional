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
  bool _obscure = true;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código enviado a tu correo')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar código. Verifica el correo.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código incorrecto')));
    }
  }

  void _changePassword() async {
    if (passCtrl.text.isEmpty || passCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }
    setState(() => _isLoading = true);

    // 3. Guardar nueva contraseña
    final exito = await _authService.resetPassword(emailCtrl.text.trim(), passCtrl.text.trim());

    setState(() => _isLoading = false);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Contraseña actualizada!')));
      Navigator.pop(context); // Regresar
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar contraseña')));
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
            const Text('Ingresa tu correo institucional para recibir un código.'),
            const SizedBox(height: 20),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _sendCode, child: const Text('Enviar Código'))
          ],
        );
      case 1: // Pedir Código
        return Column(
          children: [
            Text('Código enviado a ${emailCtrl.text}'),
            const SizedBox(height: 20),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código OTP', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _verifyCode, child: const Text('Verificar'))
          ],
        );
      case 2: // Nueva Contraseña
        return Column(
          children: [
            const Text('Crea tu nueva contraseña'),
            const SizedBox(height: 20),
            TextField(controller: passCtrl, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Nueva Contraseña', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: confirmPassCtrl, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Confirmar', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _changePassword, child: const Text('Actualizar Contraseña'))
          ],
        );
      default: return Container();
    }
  }
}