import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:flutter/material.dart';

class WorkerClientsScreen extends StatefulWidget {
  final String workerName;
  final String workerId;
  const WorkerClientsScreen({super.key, required this.workerName, required this.workerId});

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
        // --- CAMBIO: Filtro por worker_id para que el Admin vea los clientes de este empleado ---
        stream: FirebaseFirestore.instance
            .collection('clients')
            .where('worker_id', isEqualTo: widget.workerId)
            .orderBy('updated_at', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Este trabajador aún no tiene clientes registrados'.",
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.grey)
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final clientData = docs[i].data() as Map<String, dynamic>;
              clientData['id'] = docs[i].id; // Mantenemos el ID para detalle

              return _buildClientCard(
                clientData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientDetailScreen(
                        client: clientData, 
                        isAdmin: true,
                      ),
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
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddClientScreen(
              adminAssignId: widget.workerId,
              adminAssignName: widget.workerName,
            ),
          ));
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
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.blueGrey[400], 
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