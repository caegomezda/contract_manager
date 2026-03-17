import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/services/database_service.dart'; 

// 1. VISTA DE SUPERVISORES (NIVEL 1)
class SupervisorListView extends StatelessWidget {
  const SupervisorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Supervisor"), 
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: dbService.getSupervisorsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay supervisores registrados."));
          }

          final supervisors = snapshot.data!;
          return ListView.builder(
            itemCount: supervisors.length,
            itemBuilder: (context, index) {
              final supervisor = supervisors[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(supervisor['name'] ?? 'Sin nombre'),
                subtitle: Text(supervisor['email'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerListView(
                      supervisorId: supervisor['uid'], 
                      supervisorName: supervisor['name'] ?? 'Supervisor',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 2. VISTA DE TRABAJADORES (NIVEL 2)
class WorkerListView extends StatelessWidget {
  final String supervisorId;
  final String supervisorName;

  const WorkerListView({super.key, required this.supervisorId, required this.supervisorName});

  // MÉTODO PARA MOSTRAR DIÁLOGO DE TRANSFERENCIA
  void _showTransferDialog(BuildContext context, String workerId, String workerName) {
    final DatabaseService dbService = DatabaseService();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Transferir a $workerName"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: dbService.getSupervisorsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // Filtramos para no mostrar al supervisor actual
                final others = snapshot.data!.where((s) => s['uid'] != supervisorId).toList();

                if (others.isEmpty) return const Text("No hay otros supervisores disponibles.");

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final sup = others[index];
                    return ListTile(
                      title: Text(sup['name']),
                      subtitle: const Text("Asignar como nuevo supervisor"),
                      onTap: () async {
                        await dbService.assignWorkerToSupervisor(workerId, sup['uid']);
                        if (context.mounted) {
                          Navigator.pop(context); // Cierra el diálogo
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$workerName transferido a ${sup['name']}"))
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar"))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Equipo: $supervisorName"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'worker') 
            .where('supervisor_id', isEqualTo: supervisorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Este supervisor no tiene personal asignado."));
          }

          final workers = snapshot.data!.docs;
          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final workerDoc = workers[index];
              final workerData = workerDoc.data() as Map<String, dynamic>;
              final String workerId = workerDoc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.engineering_outlined, color: Colors.indigo),
                  title: Text(workerData['name'] ?? 'Operario'),
                  subtitle: Text(workerData['email'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync_alt_rounded, color: Colors.blue),
                        tooltip: "Transferir Trabajador",
                        onPressed: () => _showTransferDialog(context, workerId, workerData['name'] ?? 'Operario'),
                      ),
                      const Icon(Icons.folder_shared_rounded, color: Colors.orange),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkerClientsView(
                        workerId: workerId,
                        workerName: workerData['name'] ?? 'Operario',
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 3. VISTA DE CLIENTES CON FUNCIÓN DE ELIMINAR (NIVEL 3)
class WorkerClientsView extends StatelessWidget {
  final String workerId;
  final String workerName;

  const WorkerClientsView({super.key, required this.workerId, required this.workerName});

  Future<void> _deleteContract(BuildContext context, String docId, String clientName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Estás seguro de que deseas eliminar el contrato de $clientName? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('clients').doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Contrato eliminado correctamente")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al eliminar: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clientes de $workerName"),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clients')
            .where('worker_id', isEqualTo: workerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Sin clientes registrados."));
          }

          final clients = snapshot.data!.docs;
          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final doc = clients[index];
              final clientData = doc.data() as Map<String, dynamic>;
              final String clientId = doc.id;
              final String clientName = clientData['name'] ?? 'Cliente';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.assignment_ind_rounded, color: Colors.blueGrey),
                  title: Text(clientName),
                  subtitle: Text("${clientData['contract_type']}\n\$${clientData['monto']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteContract(context, clientId, clientName),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}