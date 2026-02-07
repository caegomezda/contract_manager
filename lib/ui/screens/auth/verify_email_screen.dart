// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
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
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Al presionar esto, lo mandamos al login para que entre ya verificado
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/'); 
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("YA LO VERIFIQUÉ, IR AL LOGIN", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enlace reenviado correctamente"))
                  );
                }
              }, 
              child: const Text("Reenviar enlace de activación"),
            ),
          ],
        ),
      ),
    );
  }
}