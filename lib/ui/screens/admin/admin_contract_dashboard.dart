// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import 'admin_contract_editor.dart';

class AdminContractDashboard extends StatelessWidget {
  const AdminContractDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Plantillas", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getTemplatesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar plantillas: ${snapshot.error}"));
          }

          final templates = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(templates),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Text(
                  "PLANTILLAS VIGENTES", 
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    color: Colors.blueGrey, 
                    fontSize: 12,
                    letterSpacing: 1.1
                  )
                ),
              ),
              Expanded(
                child: templates.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: templates.length,
                    itemBuilder: (context, i) {
                      final item = templates[i];
                      return _buildTemplateCard(context, item);
                    },
                  ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const AdminContractEditor())
        ),
        label: const Text("NUEVA PLANTILLA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ],
        border: Border.all(color: Colors.grey[100]!)
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.description_outlined, color: Colors.indigo),
        ),
        title: Text(
          item['title'] ?? 'Sin título', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Text(
          "Usado por ${item['client_count'] ?? 0} clientes",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => AdminContractEditor(
              isReadOnly: false,
              initialData: item,
            ),
          ));
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<Map<String, dynamic>> templates) {
    final totalClients = templates.fold<int>(0, (prev, element) => prev + (element['client_count'] as int? ?? 0));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8)
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Plantillas", templates.length.toString(), Icons.copy_all_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _summaryItem("Total Firmas", totalClients.toString(), Icons.draw_rounded),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("No hay plantillas creadas", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}