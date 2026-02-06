import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista variada de clientes ficticios
    final List<Map<String, dynamic>> clients = [
      {'name': 'Restaurante El Faro', 'type': 'Mantenimiento', 'status': 'Urgente', 'color': Colors.red, 'date': '04/02/2026'},
      {'name': 'Condominio Horizonte', 'type': 'Servicios Seg.', 'status': 'Por vencer', 'color': Colors.orange, 'date': '01/02/2026'},
      {'name': 'Logística Express', 'type': 'Alquiler Equipos', 'status': 'Al día', 'color': Colors.green, 'date': '28/01/2026'},
      {'name': 'Centro Médico Salud', 'type': 'Limpieza Prof.', 'status': 'Urgente', 'color': Colors.red, 'date': '03/02/2026'},
      {'name': 'Colegio San José', 'type': 'Servicios Seg.', 'status': 'Al día', 'color': Colors.green, 'date': '15/01/2026'},
      {
        'name': 'Restaurante El Faro',
        'type': 'Mantenimiento',
        'status': 'Urgente',
        'color': Colors.red,
        'date': '04/02/2026',
        'addresses': [
          'Av. Principal #12-45, Centro',
          'Calle 50 #8-20, Zona Norte',
          'C.C. Portal del Mar, Local 203'
        ],
      },
      {
        'name': 'Condominio Horizonte',
        'type': 'Servicios Seg.',
        'status': 'Por vencer',
        'color': Colors.orange,
        'date': '01/02/2026',
        'addresses': [
          'Carrera 15 #100-10, Torre A',
          'Carrera 15 #100-10, Torre B',
          'Entrada Principal Vehicular'
        ],
      },
      {
        'name': 'Logística Express',
        'type': 'Alquiler Equipos',
        'status': 'Al día',
        'color': Colors.green,
        'date': '28/01/2026',
        'addresses': [
          'Zona Franca, Bodega 4',
          'Sede Administrativa, Edificio Capital'
        ],
      },
      {
        'name': 'Supermercados Global',
        'type': 'Limpieza Prof.',
        'status': 'Por vencer',
        'color': Colors.orange,
        'date': '03/02/2026',
        'addresses': [
          'Punto de Venta Sur, Calle 80',
          'Punto de Venta Occidente, Av. 68',
          'Bodega de Despachos, Autopista Norte'
        ],
      },
      {
        'name': 'Gimnasio FitLife',
        'type': 'Consultoría',
        'status': 'Al día',
        'color': Colors.green,
        'date': '10/01/2026',
        'addresses': [
          'Sede Country, Calle 127',
        ],
      },
    ];

    // _sortClients(clients);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, i) => _buildClientCard(
                clients[i],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientDetailScreen(client: clients[i], isAdmin: false),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mis Contratos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Gestiona tus registros diarios", style: TextStyle(color: Colors.grey)),
            ],
          ),
          CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 100, // Altura fija para que el diseño 80/20 sea simétrico
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
      child: ClipRRect( // Para que el color no se salga de los bordes redondeados
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            // SECCIÓN 80% - CONTENIDO BLANCO
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
                      "Contrato: ${client['contract'] ?? client['type']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            // SECCIÓN 20% - COLOR DE PRIORIDAD
            Expanded(
              flex: 2,
              child: Container(
                // color: client['color'], // Aquí va el Rojo, Naranja o Verde
                color: Colors.green,
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  // void _sortClients(List<Map<String, dynamic>> list) {
  //   list.sort((a, b) {
  //     // Asignamos pesos: Urgente = 0, Por vencer = 1, Al día = 2
  //     Map<String, int> priorityWeight = {
  //       'Urgente': 0,
  //       'Por vencer': 1,
  //       'Al día': 2,
  //     };
  //     int weightA = priorityWeight[a['priority'] ?? a['status']] ?? 3;
  //     int weightB = priorityWeight[b['priority'] ?? b['status']] ?? 3;
  //     return weightA.compareTo(weightB);
  //   });
  // }
}