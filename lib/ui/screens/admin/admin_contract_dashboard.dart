import 'package:flutter/material.dart';
import 'admin_contract_editor.dart';

class AdminContractDashboard extends StatelessWidget {
  const AdminContractDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de prueba: En el futuro esto vendrá de Firebase
    final List<Map<String, dynamic>> templates = [
      {'title': 'Servicio Técnico', 'clients': 15, 'last_update': '02/02/2026'},
      {'title': 'Mantenimiento Preventivo', 'clients': 42, 'last_update': '01/02/2026'},
      {'title': 'Alquiler de Equipos', 'clients': 8, 'last_update': '20/01/2026'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Contratos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: () {
              // Aquí podrías ver una gráfica de crecimiento
            },
          )
        ],
      ),
      body: Column(
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
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Último cambio: ${item['last_update']}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${item['clients']}", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        const Text("Clientes", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    onTap: () {
                      bool tieneClientes = item['clients'] > 0;
  
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => AdminContractEditor(
                          isReadOnly: tieneClientes, // Si ya tiene clientes, NO se puede editar
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminContractEditor()));
        },
        label: const Text("Nueva Plantilla"),
        icon: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildSummaryHeader(List<Map<String, dynamic>> data) {
    int totalClients = data.fold(0, (sum, item) => sum + (item['clients'] as int));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen Operativo", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text("$totalClients Clientes Activos", 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Vinculados a contratos legales", style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}