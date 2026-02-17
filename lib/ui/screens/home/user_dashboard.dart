// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:contract_manager/services/database_service.dart';

/// Panel principal para usuarios con rol de trabajador y sección de clientes para Admins.
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String _searchQuery = "";
  String _currentUserRole = "";
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  /// Carga el rol para decidir qué elementos de navegación mostrar
  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _currentUserRole = doc.data()?['role'] ?? 'worker';
          _isLoadingRole = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

  /// Cabecera dinámica con flecha de retorno para Admins/Supervisores
  Widget _buildHeader(BuildContext context) {
    final bool canPop = Navigator.canPop(context);
    // Verificamos si es un rol administrativo
    final bool isManagement = _currentUserRole == 'admin' || 
                             _currentUserRole == 'super_admin' || 
                             _currentUserRole == 'supervisor';

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 10, right: 20, bottom: 20),
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
          Row(
            children: [
              // Solo muestra flecha de retorno si puede volver atrás Y es admin/supervisor
              if (canPop && isManagement)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 5),
              Text(
                isManagement ? "Clientes" : "Mis Contratos",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Si es trabajador (no puede hacer pop), mostramos Logout
          // Si es Admin pero entró directo, también mostramos Logout
          // if (!canPop)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.grey),
              tooltip: "Cerrar Sesión",
              onPressed: () => _handleLogout(context),
            ),
        ],
      ),
    );
  }

  /// Lógica de Logout centralizada y limpia
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // Navegamos al AuthWrapper (ruta '/') para limpiar el estado
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

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
            prefixIcon: Icon(Icons.search, color: Colors.indigo),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildClientsStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getClientsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        List<Map<String, dynamic>> clients = List.from(snapshot.data!);
        clients.sort((a, b) {
          String nameA = (a['name'] ?? "").toString().toLowerCase();
          String nameB = (b['name'] ?? "").toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          _searchQuery.isEmpty 
            ? "No hay clientes registrados aún." 
            : "No se encontró ningún cliente con '$_searchQuery'.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailScreen(
            client: client, 
            isAdmin: _currentUserRole != 'worker',
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
              color: Colors.black.withValues(alpha: 0.05),
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
                  color: Colors.indigo[400],
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddClientButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const AddClientScreen())
      ),
      label: const Text("Nuevo Cliente", style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.add, color: Colors.white),
      backgroundColor: Colors.indigo,
    );
  }
}