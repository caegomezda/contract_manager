// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../data/models/client_model.dart';
import '../../../services/pdf_service.dart';
import '../../../services/database_service.dart';
import 'client_form_screen.dart';

/// Pantalla de detalle que muestra la información consolidada de un cliente.
/// 
/// Permite la edición, previsualización de documentos legales y descarga de 
/// contratos procesando dinámicamente las plantillas de Firebase.
class ClientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> client;
  final bool isAdmin;

  const ClientDetailScreen({super.key, required this.client, this.isAdmin = false});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  bool _isGenerating = false;

  /// Obtiene la plantilla de Firebase y reemplaza los marcadores {{...}} con datos reales.
  Future<String> _getProcessedTerms() async {
    String contractTitle = widget.client['contract_type'] ?? 'Servicio Técnico';
    final templateData = await DatabaseService().getTemplateByTitle(contractTitle);
    
    String termsBody = templateData?['body'] ?? "Contrato de prestación de servicios para {{nombre}}.";

    // Lógica de reemplazo de variables (Hotkeys)
    return termsBody
        .replaceAll('{{nombre}}', widget.client['name'] ?? '')
        .replaceAll('{{id}}', widget.client['client_id'] ?? '')
        .replaceAll('{{fecha}}', DateTime.now().toString().split(' ')[0])
        .replaceAll('{{direcciones}}', (widget.client['addresses'] as List?)?.join(", ") ?? '');
  }

  /// Genera y abre el visor de PDF integrado.
  Future<void> _processAndPreviewPDF(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      String processedTerms = await _getProcessedTerms();
      await PdfService.previewContract(context, widget.client, processedTerms);
    } catch (e) {
      _showErrorSnackBar("Error al procesar PDF: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Procesa el texto y dispara la descarga del archivo al dispositivo.
  Future<void> _processAndDownloadPDF(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      String processedTerms = await _getProcessedTerms();
      await PdfService.downloadContract(context, widget.client, processedTerms);
    } catch (e) {
      _showErrorSnackBar("Error al descargar: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detalle"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isGenerating 
        ? _buildLoadingState()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 20),
                _buildUpdateBtn(),
                const SizedBox(height: 25),
                _buildSectionTitle("INFORMACIÓN DEL CLIENTE"),
                const Divider(),
                _infoRow(Icons.business, "Nombre / Razón Social", widget.client['name'] ?? 'N/A'),
                _infoRow(Icons.badge, "Identificación", widget.client['client_id'] ?? 'N/A'),
                _infoRow(Icons.description, "Tipo de Contrato", widget.client['contract_type'] ?? 'Servicio Estándar'),
                
                if (widget.client['addresses'] != null) ...[
                  const SizedBox(height: 10),
                  _buildAddressesSection(),
                ],

                const SizedBox(height: 30),
                _buildSectionTitle("EVIDENCIA Y SEGURIDAD"),
                const Divider(),
                const SizedBox(height: 15),
                _buildPhotoSection(),
                
                const SizedBox(height: 25),
                _buildSectionTitle("FIRMA REGISTRADA"),
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

  // --- COMPONENTES DE INTERFAZ ---

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 15),
          Text("Procesando ...", style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.1)
    );
  }

  Widget _buildStatusHeader() {
    const Color statusColor = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: statusColor),
          SizedBox(width: 12),
          Text("ACTIVO", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
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
        label: const Text("MODIFICAR DATOS", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
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
          height: 220,
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
              elevation: 0,
            ),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text("Ver Contrato", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isGenerating ? null : () => _processAndDownloadPDF(context),
          icon: const Icon(Icons.file_download_outlined, color: Colors.blueAccent),
          label: const Text("Descargar Contrato", style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildAddressesSection() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on_outlined, color: Colors.blueAccent),
      title: const Text("Direcciones Vinculadas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: (widget.client['addresses'] as List).map((dir) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 40),
        title: Text(dir.toString(), style: const TextStyle(fontSize: 13)),
        leading: const Icon(Icons.arrow_right, size: 18, color: Colors.grey),
      )).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: Colors.blueGrey),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}