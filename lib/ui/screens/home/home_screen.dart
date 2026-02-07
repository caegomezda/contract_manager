import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Importar Firebase Auth
import './admin_dashboard.dart'; 
import './user_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final String mockRole;
  const HomeScreen({super.key, required this.mockRole});

  // 2. Función optimizada para cerrar sesión
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // El AuthWrapper en main.dart se encargará de enviarte al Login automáticamente.
      // Pero por seguridad, limpiamos el stack de navegación:
      if (!context.mounted) return;
      // Esto limpia la pantalla y te manda al login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Cargando Home con rol: $mockRole");

    return Scaffold(
      appBar: AppBar(
        title: Text(mockRole == 'admin' ? "Panel Admin" : "Mis Contratos"),
        backgroundColor: mockRole == 'admin' ? Colors.indigo : Colors.blueAccent, // Diferenciación visual
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              _logout(context);
            },
          ),
        ],
      ),
      // Mantenemos la lógica de dashboards
      body: mockRole == 'admin' ? const AdminDashboard() : const UserDashboard(),
    );
  }
}