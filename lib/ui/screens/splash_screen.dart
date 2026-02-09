import 'dart:async';
import 'package:flutter/material.dart';
import 'package:contract_manager/main.dart';

/// Pantalla de bienvenida (Splash Screen) que se muestra al iniciar la aplicación.
/// 
/// Realiza una pausa estética para mostrar la marca y luego redirige al 
/// [AuthWrapper] para gestionar la sesión del usuario.
class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  
  @override
  void initState() {
    super.initState();
    _navigateToNextStep();
  }

  /// Gestiona la transición temporizada hacia la lógica de autenticación.
  void _navigateToNextStep() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
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
            // Representación visual de la marca / Logo
            const Icon(
              Icons.assignment_turned_in_rounded, 
              size: 100, 
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            
            const Text(
              "CONTRACT MANAGER",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            
            // Indicador de carga para comunicar actividad al usuario
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}