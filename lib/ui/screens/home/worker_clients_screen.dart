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
  // Datos unificados para evitar errores de ordenamiento
  final List<Map<String, dynamic>> _clients = [
    {
      'name': 'Panadería Central', 
      'contract': 'Mantenimiento', 
      'status': 'Al día', 
      'color': Colors.green,
      'addresses': ['Calle 10 #4-20'],
      'date': '01/02/2026'
    },
    {
      'name': 'Hotel Plaza', 
      'contract': 'Servicios Seg.', 
      'status': 'Por vencer', 
      'color': Colors.orange,
      'addresses': ['Av. El Sol #45'],
      'date': '02/02/2026'
    },
    {
      'name': 'Restaurante El Faro',
      'contract': 'Mantenimiento',
      'status': 'Urgente',
      'color': Colors.red,
      'date': '04/02/2026',
      'addresses': [
        'Av. Principal #12-45, Centro',
        'Calle 50 #8-20, Zona Norte',
      ],
    },
    {
      'name': 'Supermercados Global',
      'contract': 'Limpieza Prof.',
      'status': 'Por vencer',
      'color': Colors.orange,
      'date': '03/02/2026',
      'addresses': ['Punto de Venta Sur', 'Punto de Venta Norte'],
    },
  ];

  // Función de ordenamiento por peso de prioridad
  // void _sortClients(List<Map<String, dynamic>> list) {
  //   list.sort((a, b) {
  //     Map<String, int> priorityWeight = {
  //       'Urgente': 0,
  //       'Por vencer': 1,
  //       'Al día': 2,
  //     };
  //     int weightA = priorityWeight[a['status']] ?? 3;
  //     int weightB = priorityWeight[b['status']] ?? 3;
  //     return weightA.compareTo(weightB);
  //   });
  // }

  // void _changePriority(int index) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  //     builder: (context) => Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.all(16.0),
  //           child: Text("Cambiar Prioridad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //         ),
  //         _priorityOption(index, 'Urgente', Colors.red),
  //         _priorityOption(index, 'Por vencer', Colors.orange),
  //         _priorityOption(index, 'Al día', Colors.green),
  //         const SizedBox(height: 20),
  //       ],
  //     ),
  //   );
  // }

  // Widget _priorityOption(int index, String label, Color color) {
  //   return ListTile(
  //     leading: Icon(Icons.circle, color: color),
  //     title: Text(label),
  //     onTap: () {
  //       setState(() {
  //         _clients[index]['status'] = label;
  //         _clients[index]['color'] = color;
  //       });
  //       Navigator.pop(context);
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // _sortClients(_clients); // Ordenar antes de renderizar

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Clientes de ${widget.workerName}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _clients.length,
        itemBuilder: (context, i) => _buildClientCard(
          _clients[i],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // isAdmin: true permite que el jefe modifique la prioridad desde el detalle
                builder: (context) => ClientDetailScreen(client: _clients[i], isAdmin: true),
              ),
            );
          },
          // onLongPress: () => _changePriority(i),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen()));
        }, // Aquí irá el formulario con firma
        label: const Text("Nuevo Cliente"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
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
                        client['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Contrato: ${client['contract'] ?? 'Sin especificar'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  // color: client['color'],
                  color: Colors.green,
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