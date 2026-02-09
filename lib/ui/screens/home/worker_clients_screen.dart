import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:flutter/material.dart';

/// Pantalla que visualiza la lista de clientes asociados a un trabajador específico.
/// Permite al administrador buscar, filtrar y asignar nuevos clientes a dicho trabajador.
class WorkerClientsScreen extends StatefulWidget {
  final String workerName;
  final String workerId;

  const WorkerClientsScreen({
    super.key,
    required this.workerName,
    required this.workerId,
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
        title: Text(widget.workerName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildClientsList()),
        ],
      ),
      floatingActionButton: _buildAddClientButton(),
    );
  }

  /// Construye el campo de búsqueda con estilo optimizado.
  Widget _buildSearchBar() {
    return Padding(
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
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          decoration: const InputDecoration(
            hintText: "Buscar cliente asignado...",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  /// Gestiona la conexión con Firestore y procesa la lista de clientes en tiempo real.
  /// Incluye lógica de ordenamiento alfabético y filtrado por texto en memoria.
  Widget _buildClientsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clients')
          .where('worker_id', isEqualTo: widget.workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Procesamiento de datos: Mapeo y ordenamiento A-Z
        List<Map<String, dynamic>> clients = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        clients.sort((a, b) {
          String nameA = (a['name'] ?? "").toString().toLowerCase();
          String nameB = (b['name'] ?? "").toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        // Aplicación de filtro de búsqueda
        final filteredClients = clients.where((client) {
          final name = (client['name'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredClients.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredClients.length,
          itemBuilder: (context, i) => _buildClientCard(filteredClients[i]),
        );
      },
    );
  }

  /// Muestra un mensaje informativo cuando no hay clientes que coincidan con la búsqueda o la asignación.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          _searchQuery.isEmpty
              ? "Este trabajador aún no tiene clientes."
              : "No se encontró nada para '$_searchQuery'",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// Construye la representación visual de cada cliente.
  Widget _buildClientCard(Map<String, dynamic> client) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailScreen(
            client: client,
            isAdmin: true,
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
              color: Colors.black.withValues(alpha: 0.1),
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

  /// Botón de acción para que el administrador asigne manualmente un nuevo cliente a este trabajador.
  Widget _buildAddClientButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddClientScreen(
              adminAssignId: widget.workerId,
              adminAssignName: widget.workerName,
            ),
          ),
        );
      },
      label: const Text("Asignar Nuevo"),
      icon: const Icon(Icons.add),
      backgroundColor: Colors.blueAccent,
    );
  }
}