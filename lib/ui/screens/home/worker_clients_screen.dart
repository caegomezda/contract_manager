import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:flutter/material.dart';

class WorkerClientsScreen extends StatefulWidget {
  final String workerName;
  const WorkerClientsScreen({super.key, required this.workerName});

  @override
  State<WorkerClientsScreen> createState() => _WorkerClientsScreenState();
}

class _WorkerClientsScreenState extends State<WorkerClientsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Clientes de ${widget.workerName}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FILTRO: Solo traemos los clientes donde el nombre del trabajador coincida
        stream: FirebaseFirestore.instance
            .collection('clients')
            .where('worker_name', isEqualTo: widget.workerName) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error al cargar datos"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text("Este trabajador aún no tiene clientes registrados.",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final clientData = docs[i].data() as Map<String, dynamic>;
              // Agregamos el ID del documento para que ClientDetailScreen pueda usarlo
              clientData['id'] = docs[i].id;

              return _buildClientCard(
                clientData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Al ser Admin, puede editar o cambiar prioridades
                      builder: (context) => ClientDetailScreen(client: clientData, isAdmin: true),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen()));
        },
        label: const Text("Asignar Nuevo"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
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
                      const SizedBox(height: 4),
                      Text(
                        "Contrato: ${client['contract_type'] ?? 'No especificado'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.blueGrey[400], // Color neutral para vista de Admin
                  child: const Center(
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}