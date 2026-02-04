import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 30),
            const Text("Verifica tu correo", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Hemos enviado un enlace a tu correo. Por favor, haz clic en él para activar tu cuenta.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text("YA LO VERIFIQUÉ"),
              ),
            ),
            TextButton(onPressed: () {}, child: const Text("Reenviar código")),
          ],
        ),
      ),
    );
  }
}