import 'package:contract_manager/ui/screens/home/add_client_screen.dart';
import 'package:contract_manager/ui/screens/home/client_detail_screen.dart';
import 'package:contract_manager/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context), // Mantenemos tu header
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Ahora el servicio filtrará automáticamente por el UID del usuario logueado
              stream: DatabaseService().getClientsStream(), 
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final clients = snapshot.data!;

                if (clients.isEmpty) {
                  return const Center(child: Text("No tienes clientes registrados aún."));
                }

                return ListView.builder(
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen()));
        },
        label: const Text("Nuevo Cliente"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(110, 255, 255, 255),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Envolvemos el título en Expanded para que no empuje a los iconos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Mis Contratos", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
           // Los iconos ahora se mantendrán a la derecha sin desbordar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ],
          ),
        ],
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
              color: Colors.black.withValues(alpha: 0.5), // Opacidad corregida para evitar errores
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            // Usamos CrossAxisAlignment.stretch para que el botón lateral 
            // siempre ocupe todo el alto de la tarjeta de forma uniforme
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Un poco menos de padding ayuda al espacio
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
                      // SOLUCIÓN AL OVERFLOW: 
                      // Añadimos maxLines y ellipsis también aquí para que 
                      // textos largos como "Servicio Técnico" no rompan la tarjeta
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
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[400],
                    // Si tu tarjeta tiene bordes redondeados, asegúrate de redondear 
                    // solo los del lado derecho del botón para que encaje perfecto
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
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