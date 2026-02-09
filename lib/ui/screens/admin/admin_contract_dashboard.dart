import 'package:contract_manager/services/database_service.dart';
import 'package:flutter/material.dart';
import 'admin_contract_editor.dart';

class AdminContractDashboard extends StatelessWidget {
  const AdminContractDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Contratos")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getTemplatesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final templates = snapshot.data ?? [];

          return Column(
            children: [
              _buildSummaryHeader(templates),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("PLANTILLAS VIGENTES", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, i) {
                    final item = templates[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text(item['title'] ?? 'Sin título', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => AdminContractEditor(
                              isReadOnly: false, // Puedes implementar lógica de bloqueo luego
                              initialData: item,
                            ),
                          ));
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => const AdminContractEditor())),
        label: const Text("Nueva Plantilla"),
        icon: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildSummaryHeader(List<Map<String, dynamic>> templates) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Plantillas", templates.length.toString(), Icons.layers),
          _summaryItem(
            "Total Clientes", 
            // Suma segura manejando nulos
            templates.fold<int>(0, (prev, element) => prev + (element['client_count'] as int? ?? 0)).toString(), 
            Icons.people
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}