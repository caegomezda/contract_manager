import 'package:flutter/material.dart';
// REGLA DE ORO: Usa rutas relativas directas si la absoluta falla
import './admin_dashboard.dart'; 
import './user_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final String mockRole;
  const HomeScreen({super.key, required this.mockRole});

  @override
  Widget build(BuildContext context) {
    // Diagnóstico: Imprime en consola para ver qué está llegando
    debugPrint("Cargando Home con rol: $mockRole");

    return Scaffold(
      appBar: AppBar(
        title: Text(mockRole == 'admin' ? "Panel Admin" : "Mis Contratos"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'), 
            icon: const Icon(Icons.logout)
          )
        ],
      ),
      // Si el error sigue aquí, es que los archivos de abajo tienen un error interno
      body: mockRole == 'admin' ? const AdminDashboard() : const UserDashboard(),
    );
  }
}