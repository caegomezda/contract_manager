// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Pantalla de espera para que el usuario verifique su correo electrónico.
/// Esencial para la seguridad del sistema de contratos.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono animado o estilizado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined, 
                  size: 100, 
                  color: Colors.indigo
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                "¡Casi listo!", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              const SizedBox(height: 12),
              
              const Text(
                "Hemos enviado un enlace de activación a tu correo.\n\nPor favor, revisa tu bandeja de entrada (y la carpeta de spam) para activar tu cuenta.",
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 50),
              
              // Botón Principal
              SizedBox(
                width: double.infinity, 
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    // Cerrar sesión asegura que el token se refresque al volver a entrar
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, '/'); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "YA LO VERIFIQUÉ, IR AL INICIO", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Opción de reenvío con feedback
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () async {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Enlace reenviado correctamente"),
                          behavior: SnackBarBehavior.floating,
                        )
                      );
                    } else {
                      _showError(context, "No se encontró un usuario activo. Por favor reingresa.");
                    }
                  } catch (e) {
                    _showError(context, "Espera un momento antes de solicitar otro reenvío.");
                  }
                }, 
                label: const Text(
                  "Reenviar enlace de activación",
                  style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                ),
              ),
              
              const SizedBox(height: 10),
              
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacementNamed(context, '/')),
                child: const Text("Cancelar y volver", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      )
    );
  }
}