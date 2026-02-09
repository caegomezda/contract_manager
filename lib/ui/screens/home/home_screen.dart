import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './admin_dashboard.dart'; 
import './user_dashboard.dart';

/// Pantalla puente que alterna entre vistas según el rol del usuario.
/// 
/// Actúa como un contenedor principal que diferencia visualmente la interfaz
/// para administradores y trabajadores, gestionando además el estado de la sesión.
class HomeScreen extends StatelessWidget {
  final String mockRole;
  
  const HomeScreen({super.key, required this.mockRole});

  /// Realiza el cierre de sesión en Firebase y limpia el historial de navegación.
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (!context.mounted) return;

      // Reinicia el flujo de la aplicación hacia la pantalla de login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Identificamos si el perfil es administrativo
    final bool isAdmin = mockRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "Panel Administrativo" : "Mis Contratos"),
        centerTitle: true,
        backgroundColor: isAdmin ? Colors.indigo : Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Cerrar Sesión",
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      // Inyección dinámica del dashboard correspondiente al rol
      body: isAdmin ? const AdminDashboard() : const UserDashboard(),
    );
  }
}