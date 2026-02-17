// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:contract_manager/data/models/user_model.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TokenLockScreen extends StatefulWidget {
  final UserModel user;
  const TokenLockScreen({super.key, required this.user});

  @override
  State<TokenLockScreen> createState() => _TokenLockScreenState();
}

class _TokenLockScreenState extends State<TokenLockScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isError = false;
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final inputCode = _codeController.text.trim();
    
    // 1. Verificamos contra el authCode del modelo
    if (inputCode == widget.user.authCode) {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      try {
        // 2. ACTUALIZACIÓN EN FIRESTORE: Extendemos el acceso
        // Por defecto, al poner el código correcto, le damos 30 días más
        final DateTime newExpiry = DateTime.now().add(const Duration(days: 30));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
          'auth_valid_until': newExpiry.toIso8601String(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // 3. ÉXITO: Navegamos a la pantalla principal
        if (!mounted) return;
        
        // Usamos pushNamedAndRemoveUntil para limpiar el historial de navegación
        // y que no puedan volver atrás a la pantalla de bloqueo.
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar el acceso. Inténtalo de nuevo."))
        );
      }
    } else {
      // CÓDIGO INCORRECTO
      setState(() {
        _isError = true;
        _codeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos WillPopScope para evitar que el usuario regrese con el botón físico
      body: PopScope(
        canPop: false,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)], // Rojo intenso
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                "ACCESO EXPIRADO",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Tu periodo de acceso ha terminado.\nPor seguridad, ingresa el nuevo código proporcionado por tu administrador.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                obscureText: true, // Para que no se vea el código al escribir
                style: const TextStyle(
                  fontSize: 32, 
                  letterSpacing: 20, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "****",
                  hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 10),
                  errorText: _isError ? "Código incorrecto" : null,
                  errorStyle: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  counterText: "",
                ),
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.red)
                    : const Text(
                        "VERIFICAR Y ACTIVAR",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              TextButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  "Cerrar Sesión", 
                  style: TextStyle(color: Colors.white, fontSize: 16)
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}