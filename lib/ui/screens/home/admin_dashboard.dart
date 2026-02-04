// ignore_for_file: deprecated_member_use

import 'package:contract_manager/ui/screens/admin/admin_contract_dashboard.dart';
import 'package:flutter/material.dart';
import 'worker_clients_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> workers = [
      {'name': 'Carlos Mendoza', 'role': 'Ventas Norte', 'clients': 12, 'active': true},
      {'name': 'Lucía Fernández', 'role': 'Ventas Sur', 'clients': 8, 'active': true},
      {'name': 'Roberto Gómez', 'role': 'Terreno', 'clients': 5, 'active': false},
    ];

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar estilizado
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
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
                      // Botón para ir a PDF y Plantillas
                      _topMenuButton(
                        context, 
                        Icons.picture_as_pdf, 
                        "Contratos", 
                        Colors.redAccent,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminContractDashboard()))
                      ),
                      // _topMenuButton(
                      //   context, 
                      //   Icons.analytics, 
                      //   "Reportes", 
                      //   Colors.blueAccent,
                      //   () { /* Tu lógica de reportes */ }
                      // ),
                      // _topMenuButton(
                      //   context, 
                      //   Icons.settings, 
                      //   "Ajustes", 
                      //   Colors.grey,
                      //   () { /* Ajustes de la app */ }
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Título de la lista de trabajadores
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("EQUIPO DE TRABAJO", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            ),
          ),

          // Lista de trabajadores
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _workerCard(context, workers[i]),
              childCount: workers.length,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para los botones superiores de acceso rápido
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: worker['active'] ? Colors.green[100] : Colors.grey[200],
          child: Icon(Icons.person, color: worker['active'] ? Colors.green : Colors.grey),
        ),
        title: Text(worker['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${worker['role']} • ${worker['clients']} clientes"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerClientsScreen(workerName: worker['name']),
            ),
          );
        },
      ),
    );
  }
}