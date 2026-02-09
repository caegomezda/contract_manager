// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../data/models/client_model.dart';
import '../../../services/pdf_service.dart';
import '../../../services/database_service.dart';
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

  /// Lógica dinámica para obtener la plantilla y generar el PDF
  Future<void> _processAndPreviewPDF(BuildContext context) async {
    setState(() => _isGenerating = true);
    
    try {
      // 1. Obtener el cuerpo del contrato desde Firebase usando el título
      String contractTitle = widget.client['contract_type'] ?? 'Servicio Técnico';
      String termsBody = "";

      final templateData = await DatabaseService().getTemplateByTitle(contractTitle);
      
      if (templateData != null) {
        termsBody = templateData['body'] ?? "";
      } else {
        termsBody = "Contrato de prestación de servicios para {{nombre}}.";
      }

      // 2. Reemplazar variables dinámicas (Hotkeys)
      String processedTerms = termsBody
          .replaceAll('{{nombre}}', widget.client['name'] ?? '')
          .replaceAll('{{id}}', widget.client['client_id'] ?? '')
          .replaceAll('{{fecha}}', DateTime.now().toString().split(' ')[0])
          .replaceAll('{{direcciones}}', (widget.client['addresses'] as List?)?.join(", ") ?? '');

      // 3. Lanzar la previsualización
      await PdfService.previewContract(
        context,
        widget.client,
        processedTerms,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error al procesar PDF: $e")),
      );
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
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 15),
              Text("Procesando documento legal...")
            ],
          )) 
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
                _infoRow(Icons.business, "Nombre / Razón Social", widget.client['name'] ?? 'N/A'),
                _infoRow(Icons.badge, "Identificación", widget.client['client_id'] ?? 'N/A'),
                _infoRow(Icons.description, "Tipo de Contrato", widget.client['contract_type'] ?? 'Servicio Estándar'),
                
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
                const Text("FIRMA REGISTRADA", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                _buildSignatureCanvas(),
                
                const SizedBox(height: 30),
                _buildActionButtons(),
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
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: statusColor),
          SizedBox(width: 12),
          Text("CONTRATO VIGENTE", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpdateBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
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
        icon: const Icon(Icons.edit_note, color: Colors.orange),
        label: const Text("EDITAR INFORMACIÓN", style: TextStyle(color: Colors.orange)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orange),
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
        const Text("Registro Fotográfico", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
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
    final String? sigBase64 = widget.client['signature_path'];
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: sigBase64 != null && sigBase64.isNotEmpty
            ? Image.memory(base64Decode(sigBase64), fit: BoxFit.contain)
            : const Center(child: Text("Sin firma registrada", style: TextStyle(color: Colors.grey))),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () => _processAndPreviewPDF(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.remove_red_eye, color: Colors.white),
            label: const Text("VER CONTRATO PDF", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => PdfService.downloadContract(context, widget.client, "Cuerpo del contrato..."),
          icon: const Icon(Icons.download, color: Colors.blueAccent),
          label: const Text("Descargar archivo"),
        )
      ],
    );
  }

  Widget _buildAddressesSection() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on, color: Colors.blueAccent),
      title: const Text("Sedes / Direcciones", style: TextStyle(fontWeight: FontWeight.bold)),
      children: (widget.client['addresses'] as List).map((dir) => ListTile(
        dense: true,
        title: Text(dir.toString()),
        leading: const Icon(Icons.circle, size: 6, color: Colors.grey),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}