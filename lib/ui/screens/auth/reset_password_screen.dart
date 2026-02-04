import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Acceso")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Text("Ingresa tu correo y te enviaremos un link para cambiar tu contraseña."),
            const SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ENVIAR CORREO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}