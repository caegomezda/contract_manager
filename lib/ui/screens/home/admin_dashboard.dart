// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/admin/admin_contract_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'worker_clients_screen.dart';

/// Panel Principal para Administradores.
/// 
/// Permite gestionar las plantillas de contratos y supervisar la actividad
/// de los trabajadores en tiempo real conectándose a la colección 'users'.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  /// Cierra la sesión de Firebase y redirige al Login.
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                "EQUIPO DE TRABAJO", 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.blueGrey, 
                  fontSize: 12,
                  letterSpacing: 1.2
                ),
              ),
            ),
          ),

          // Stream en tiempo real de los usuarios registrados
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: _buildErrorState(snapshot.error.toString()),
                );
              }
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  )),
                );
              }
              
              final workers = snapshot.data!.docs;

              if (workers.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text("No hay trabajadores registrados")),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final workerData = workers[i].data() as Map<String, dynamic>;
                    // Inyectamos el ID del documento para poder filtrar sus clientes luego
                    workerData['id'] = workers[i].id; 
                    return _workerCard(context, workerData);
                  },
                  childCount: workers.length,
                ),
              );
            },
          ),
          
          // Espaciador final para que el último card no quede pegado al borde
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  // --- COMPONENTES INTERNOS ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.indigo,
      actions: [
        IconButton(
          tooltip: "Cerrar Sesión",
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _handleLogout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo, Colors.indigoAccent],
            ),
          ),
          child: Stack(
            children: [
              // Círculos decorativos de fondo
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.1)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50, left: 20),
                child: Row(
                  children: [
                    _topMenuButton(
                      context, 
                      Icons.description_rounded, 
                      "Plantillas", 
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminContractDashboard()))
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topMenuButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _workerCard(BuildContext context, Map<String, dynamic> worker) {
    // Verificamos si es un trabajador o un administrador
    bool isWorker = worker['role']?.toString().toLowerCase() == 'worker';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isWorker ? Colors.blue[50] : Colors.amber[50],
          child: Icon(
            isWorker ? Icons.engineering_rounded : Icons.admin_panel_settings_rounded, 
            color: isWorker ? Colors.blue : Colors.amber[800]
          ),
        ),
        title: Text(
          worker['name'] ?? 'Usuario sin nombre', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
          child: Text(
            "${worker['email'] ?? 'Sin correo'}\nRol: ${worker['role'] ?? 'No asignado'}",
            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerClientsScreen(
                workerName: worker['name'] ?? 'Desconocido',
                workerId: worker['id'],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: Text("Error al cargar equipo: $error", style: const TextStyle(color: Colors.red)),
    );
  }
}