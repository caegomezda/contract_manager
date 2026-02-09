import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:flutter/material.dart';

class WorkerClientsScreen extends StatefulWidget {
  final String workerName;
  final String workerId;
  const WorkerClientsScreen({
    super.key, 
    required this.workerName, 
    required this.workerId
  });

  @override
  State<WorkerClientsScreen> createState() => _WorkerClientsScreenState();
}

class _WorkerClientsScreenState extends State<WorkerClientsScreen> {
  String _searchQuery = ""; 

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
      body: Column(
        children: [
          // --- BUSCADOR OPTIMIZADO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                onChanged: (val) {
                  setState(() {
                    // Eliminamos espacios extras para una búsqueda más limpia
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Buscar cliente asignado...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clients')
                  .where('worker_id', isEqualTo: widget.workerId)
                  // Nota: No podemos ordenar por nombre en Firebase y filtrar por worker_id 
                  // sin crear un índice compuesto, por eso ordenamos en memoria (más rápido).
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // 1. Convertimos a lista de Mapas
                List<Map<String, dynamic>> clients = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                // 2. ORDEN ALFABÉTICO POR DEFECTO (A-Z)
                clients.sort((a, b) {
                  String nameA = (a['name'] ?? "").toString().toLowerCase();
                  String nameB = (b['name'] ?? "").toString().toLowerCase();
                  return nameA.compareTo(nameB);
                });

                // 3. FILTRADO DINÁMICO
                final filteredClients = clients.where((client) {
                  final name = (client['name'] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        _searchQuery.isEmpty 
                          ? "Este trabajador aún no tiene clientes." 
                          : "No se encontró nada para '$_searchQuery'",
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.grey)
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, i) {
                    return _buildClientCard(
                      filteredClients[i],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailScreen(
                              client: filteredClients[i], 
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
          ),
        ],
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
                      const SizedBox(height: 4),
                      Text(
                        "Contrato: ${client['contract_type'] ?? 'No especificado'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
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