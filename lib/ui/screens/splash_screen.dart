import 'package:flutter/material.dart';
import 'dart:async';
import 'package:contract_manager/main.dart'; // O tu pantalla de AuthWrapper

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Duración de 3 segundos y navega al AuthWrapper
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes poner tu logo
            const Icon(Icons.assignment_turned_in_rounded, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "CONTRACT MANAGER",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}