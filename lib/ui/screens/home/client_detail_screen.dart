// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:contract_manager/data/models/client_model.dart';
import 'package:contract_manager/services/pdf_service.dart';
import 'package:contract_manager/services/database_service.dart'; // Asegúrate de importar esto
import 'package:flutter/material.dart';
import 'dart:convert';
import 'client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> client;
  final bool isAdmin;

  const ClientDetailScreen({super.key, required this.client, this.isAdmin = false});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  bool _isGenerating = false;

  // ignore: unused_element
  Future<void> _generatePDF(BuildContext context) async {
    setState(() => _isGenerating = true);
    // ignore: unused_local_variable
    String termsText = ""; 
    
    try {
      String templateId = (widget.client['contract_type'] ?? 'servicio_estandar')
          .toString().toLowerCase().trim().replaceAll(' ', '_');
      
      try {
        // Ahora este método sí existirá en DatabaseService
        final templateDoc = await DatabaseService().getTemplate(templateId);
        
        if (templateDoc.exists) {
          termsText = (templateDoc.data() as Map<String, dynamic>)['body'] ?? "";
        } else {
          throw "TemplateNotFound"; 
        }
      } catch (e) {
        // Reemplazamos print por un comentario o lógica silenciosa de respaldo
        termsText = "Contrato de servicio para {{nombre}}. ID: {{id}}. Acepto los términos de {{contrato}}.";
        // Si necesitas loguear en desarrollo usa: debugPrint("Usando respaldo: $e");
      }

      await PdfService.previewContract(
        context,                      
        widget.client,                
        widget.client['terms_text'] ?? ''
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("PDF generado con éxito")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Error fatal: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
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
      body: _isGenerating 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 20),
                _buildUpdateBtn(),
                const SizedBox(height: 25),
                const Text("INFORMACIÓN DEL CLIENTE", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const Divider(),
                _infoRow(Icons.business, "Nombre", widget.client['name'] ?? 'N/A'),
                _infoRow(Icons.description, "Tipo de Contrato", widget.client['contract_type'] ?? 'Servicio Estándar'),
                _infoRow(Icons.calendar_today, "Última Actualización", "06/02/2026"),
                
                if (widget.client['addresses'] != null) ...[
                  const SizedBox(height: 10),
                  _buildAddressesSection(),
                ],

                const SizedBox(height: 30),
                const Text("EVIDENCIA Y SEGURIDAD", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const Divider(),
                const SizedBox(height: 15),
                _buildPhotoSection(),
                
                const SizedBox(height: 25),
                const Text("FIRMA DEL CONTRATO", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                _buildSignatureCanvas(),
                
                const SizedBox(height: 30),
                _buildDownloadButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildStatusHeader() {
    const Color statusColor = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1), // Corrección: withValues
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: statusColor),
          const SizedBox(width: 12),
          Text("ACTIVO", style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
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
            workerId: widget.client['worker_id'],
            addresses: List<String>.from(widget.client['addresses'] ?? []),
            photoUrl: widget.client['photo_data_base64'],
            signatureBase64: widget.client['signature_path'],
            termsAccepted: widget.client['terms_accepted'] ?? false,
            lastUpdate: DateTime.now(),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => ClientFormScreen(existingClient: clientModel)));
        },
        label: const Text("ACTUALIZAR", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final String? photoBase64 = widget.client['photo_data_base64'] ?? widget.client['photo_url'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Foto del Local / Fachada", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!, width: 2),
          ),
          child: photoBase64 != null && photoBase64.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(base64Decode(photoBase64), fit: BoxFit.cover),
                )
              : const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
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
                : const Center(child: Text("Sin firma registrada")),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 2)
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 35),
              onPressed: () => PdfService.previewContract(context, widget.client, widget.client['terms_text'] ?? ''),
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
      // USAMOS LA FUNCIÓN DE DESCARGA DIRECTA
      onPressed: () => PdfService.downloadContract(context, widget.client, widget.client['terms_text'] ?? ''),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.file_download, color: Colors.white),
      label: const Text("DESCARGAR PDF", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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