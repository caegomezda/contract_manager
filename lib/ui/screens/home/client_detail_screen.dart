// ignore_for_file: deprecated_member_use

import 'package:contract_manager/data/models/client_model.dart';
import 'package:contract_manager/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'client_form_screen.dart'; // Asegúrate de crear este archivo

class ClientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> client;
  final bool isAdmin;

  const ClientDetailScreen({super.key, required this.client, this.isAdmin = false});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  // File? _imageFile;
  // final ImagePicker _picker = ImagePicker();

  // Función para capturar foto del local/cliente
  // Future<void> _pickImage() async {
  //   final XFile? pickedFile = await _picker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 50, // Comprimimos para no saturar la base de datos
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _imageFile = File(pickedFile.path);
  //     });
  //     // Aquí podrías disparar la subida a Firebase Storage
  //   }
  // }

  void _generatePDF(BuildContext context) {
    // Aquí traerás la plantilla real de Firestore en el siguiente paso
    String miPlantillaHardcoded = "Yo {{nombre}}, con ID {{id}}, acepto el contrato...";
    PdfService.generateFinalContract(widget.client, miPlantillaHardcoded);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
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
            // 1. Cabecera de Estado (FIJO VERDE según requerimiento)
            _buildStatusHeader(),
            const SizedBox(height: 20),

            // 2. Botón de Actualizar / Renovar
            _buildUpdateBtn(),
            const SizedBox(height: 25),

            const Text("INFORMACIÓN DEL CLIENTE", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const Divider(),
            
            _infoRow(Icons.business, "Nombre", widget.client['name'] ?? widget.client['client_name'] ?? 'N/A'),
            _infoRow(Icons.description, "Tipo de Contrato", widget.client['contract'] ?? widget.client['contract_type'] ?? 'Servicio Estándar'),
            _infoRow(Icons.calendar_today, "Última Actualización", widget.client['date']?.toString().split('T')[0] ?? "06/02/2026"),
            
            // Sección de Direcciones
            if (widget.client['addresses'] != null) ...[
              const SizedBox(height: 10),
              _buildAddressesSection(),
            ],

            const SizedBox(height: 30),
            const Text("EVIDENCIA Y SEGURIDAD", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const Divider(),
            
            // 3. SECCIÓN DE FOTO DEL LOCAL
            const SizedBox(height: 15),
            // _buildPhotoSection(),
            _buildPhotoSection(),
            
            const SizedBox(height: 25),
            const Text("FIRMA DEL CONTRATO", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),

            // 4. Contenedor de Firma con Icono PDF
            _buildSignatureCanvas(),
            
            const SizedBox(height: 30),

            // 5. Botón de Descarga
            _buildDownloadButton(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    // Ahora es fijo Verde como solicitaste
    const Color statusColor = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: statusColor),
          const SizedBox(width: 12),
          Text(
            "ACTIVO",
            style: TextStyle(color: statusColor.withOpacity(0.8), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {

          final clientModel = ClientModel(
            id: widget.client['id'],
            name: widget.client['name'] ?? '',
            clientId: widget.client['client_id'] ?? '',
            contractType: widget.client['contract_type'] ?? '',
            addresses: List<String>.from(widget.client['addresses'] ?? []),
            photoUrl: widget.client['photo_url'],
            signatureBase64: widget.client['signature_path'],
            termsAccepted: widget.client['terms_accepted'] ?? false,
            lastUpdate: DateTime.now(),
          );
          // Navegamos al formulario pasando los datos actuales para renovar
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientFormScreen(existingClient: clientModel),
            ),
          );
        },
        icon: const Icon(Icons.history_edu, color: Colors.white),
        label: const Text("ACTUALIZAR / RENOVAR CONTRATO", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
      // Intentamos obtener la imagen de los dos posibles nombres de campo
      final String? photoBase64 = widget.client['photo_data_base64'] ?? widget.client['photo_url'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Foto del Local / Fachada", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Container(
            height: 220, // Un poco más alto para que se aprecie mejor la fachada
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: photoBase64 != null && photoBase64.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.memory(
                      base64Decode(photoBase64),
                      fit: BoxFit.cover,
                      // Manejo de errores por si el Base64 está corrupto
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.red, size: 40),
                            Text("Error al cargar imagen", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text("Sin evidencia fotográfica", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
          ),
        ],
      );
    }
    
  Widget _buildSignatureCanvas() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: widget.client['signature_path'] != null && widget.client['signature_path'].isNotEmpty
                ? Image.memory(base64Decode(widget.client['signature_path']), fit: BoxFit.contain)
                : const Center(child: Text("Sin firma registrada", style: TextStyle(color: Colors.grey))),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => _generatePDF(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => _generatePDF(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.download_rounded, color: Colors.white),
        label: const Text("DESCARGAR PDF FIRMADO", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAddressesSection() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on, color: Colors.blueAccent),
      title: const Text("Direcciones Registradas", style: TextStyle(fontWeight: FontWeight.bold)),
      children: (widget.client['addresses'] as List).map((dir) => ListTile(
        dense: true,
        title: Text(dir.toString()),
        leading: const Icon(Icons.circle, size: 6),
      )).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}