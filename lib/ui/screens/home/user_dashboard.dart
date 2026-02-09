// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:contract_manager/services/database_service.dart';

/// Panel principal para usuarios con rol de trabajador.
/// 
/// Esta pantalla permite visualizar, buscar y gestionar los clientes asignados 
/// al usuario autenticado, conectándose en tiempo real con Firestore.
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  /// Almacena el texto de búsqueda introducido por el usuario.
  String _searchQuery = ""; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(),
          Expanded(child: _buildClientsStream()),
        ],
      ),
      floatingActionButton: _buildAddClientButton(),
    );
  }

  /// Construye la cabecera superior con el título y la opción de cierre de sesión.
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Mis Contratos",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: "Cerrar Sesión",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  /// Campo de búsqueda dinámico que actualiza el estado de la lista en tiempo real.
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          decoration: const InputDecoration(
            hintText: "Buscar cliente por nombre...",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  /// Gestiona la suscripción al flujo de datos de clientes desde el [DatabaseService].
  /// Realiza el procesamiento de datos: ordenamiento y filtrado por texto.
  Widget _buildClientsStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getClientsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // 1. Preparación de la lista y ordenamiento alfabético
        List<Map<String, dynamic>> clients = List.from(snapshot.data!);
        clients.sort((a, b) {
          String nameA = (a['name'] ?? "").toString().toLowerCase();
          String nameB = (b['name'] ?? "").toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        // 2. Filtrado basado en la entrada del usuario
        final filteredClients = clients.where((client) {
          final name = (client['name'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredClients.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredClients.length,
          itemBuilder: (context, i) => _buildClientCard(filteredClients[i]),
        );
      },
    );
  }

  /// Muestra una interfaz informativa cuando la lista de clientes está vacía.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          _searchQuery.isEmpty 
            ? "No tienes clientes registrados aún." 
            : "No se encontró ningún cliente con '$_searchQuery'.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// Widget de tarjeta individual para representar los datos básicos del cliente.
  Widget _buildClientCard(Map<String, dynamic> client) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailScreen(
            client: client, 
            isAdmin: false,
          ),
        ),
      ),
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        client['name'] ?? 'Cliente sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.blueGrey[400],
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón flotante para acceder a la creación de un nuevo cliente.
  Widget _buildAddClientButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const AddClientScreen())
      ),
      label: const Text("Nuevo Cliente"),
      icon: const Icon(Icons.add),
      backgroundColor: Colors.blueAccent,
    );
  }
}