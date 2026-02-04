// ignore_for_file: deprecated_member_use

import 'package:contract_manager/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ClientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> client;
  final bool isAdmin;

  const ClientDetailScreen({super.key, required this.client, this.isAdmin = false});

  void _generatePDF(BuildContext context) {

    // Aquí idealmente traerías la plantilla guardada de la DB
    String miPlantillaHardcoded = "Yo {{nombre}}, con ID {{id}}, acepto el contrato...";
      
    PdfService.generateFinalContract(client, miPlantillaHardcoded);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.blueAccent,
        content: Text("Generando documento PDF con firma digital..."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detalle del Contrato"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera de Estado
            _buildStatusHeader(),
            const SizedBox(height: 25),
            
            const Text("INFORMACIÓN DEL CLIENTE", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const Divider(),
            _infoRow(Icons.business, "Nombre", client['name'] ?? client['client_name']),
            _infoRow(Icons.description, "Tipo de Contrato", client['contract'] ?? client['contract_type'] ?? client['type']),
            _infoRow(Icons.calendar_today, "Fecha de Registro", client['date']?.toString().split('T')[0] ?? "04/02/2026"),
            
            // ==========================================================
            // NUEVA SECCIÓN: LISTADO DE DIRECCIONES DESPLEGABLE
            // ==========================================================
            if (client['addresses'] != null && (client['addresses'] as List).isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                  title: const Text("Direcciones Registradas", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${(client['addresses'] as List).length} sedes encontradas"),
                  children: (client['addresses'] as List).map((dir) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 8, color: Colors.blueGrey),
                    title: Text(dir.toString(), style: const TextStyle(fontSize: 14)),
                  )).toList(),
                ),
              ),
            ],
            // ==========================================================

            const SizedBox(height: 30),
            const Text("FIRMA REGISTRADA", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const Divider(),
            const SizedBox(height: 15),
            
            // 2. Contenedor de Firma con Icono PDF Flotante
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: client['signature_path'] != null && client['signature_path'].isNotEmpty
                        ? Image.memory(
                            base64Decode(client['signature_path']),
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Text("Firma Digital Protegida", 
                              style: TextStyle(color: Colors.grey))),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                      onPressed: () => _generatePDF(context),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),

            // 3. Botón Principal de PDF
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _generatePDF(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                label: const Text("DESCARGAR CONTRATO PDF", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 15),

            // 4. Opción para Admin
            if (isAdmin)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () { /* Lógica de prioridad */ },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text("MODIFICAR PRIORIDAD"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final Color statusColor = client['color'] ?? Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: statusColor),
          const SizedBox(width: 12),
          Text(
            "ESTADO: ${client['status'] ?? client['priority'] ?? 'Activo'}",
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blueAccent),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, 
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}