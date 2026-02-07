// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/admin/admin_contract_dashboard.dart';
import 'package:flutter/material.dart';
import 'worker_clients_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _topMenuButton(
                        context, 
                        Icons.picture_as_pdf, 
                        "Contratos", 
                        Colors.redAccent,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminContractDashboard()))
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("EQUIPO DE TRABAJO (REAL)", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            ),
          ),

          // STREAM REAL DE TRABAJADORES
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              
              final workers = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final workerData = workers[i].data() as Map<String, dynamic>;
                    // Aseguramos que tenga el ID para la navegación
                    workerData['id'] = workers[i].id; 
                    return _workerCard(context, workerData);
                  },
                  childCount: workers.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _topMenuButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _workerCard(BuildContext context, Map<String, dynamic> worker) {
    // Si no tiene el campo 'active' en Firebase, por defecto ponemos true
    bool isActive = worker['active'] ?? true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green[100] : Colors.grey[200],
          child: Icon(Icons.person, color: isActive ? Colors.green : Colors.grey),
        ),
        title: Text(worker['name'] ?? 'Usuario sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${worker['role'] ?? 'Operario'}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerClientsScreen(workerName: worker['name'] ?? 'Desconocido'),
            ),
          );
        },
      ),
    );
  }
}