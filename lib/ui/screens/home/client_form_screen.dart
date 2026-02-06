// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert'; // Importante para la firma
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart'; // Asegúrate de tener esta dependencia
import '../../../data/models/client_model.dart';
import '../../../services/database_service.dart';
import '../admin/terms_editor_screen.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientModel? existingClient;
  const ClientFormScreen({super.key, this.existingClient});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  File? _imageFile;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  // 1. Controlador de la firma
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingClient?.name ?? '');
    _idController = TextEditingController(text: widget.existingClient?.clientId ?? '');
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 600,       // Redimensiona el ancho a 600px máximo
      maxHeight: 600,      // Redimensiona el alto a 600px máximo
      imageQuality: 30,    // Comprime la calidad al 30%
    );
    
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingClient == null ? "Nuevo Cliente" : "Renovar Contrato")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("EVIDENCIA FOTOGRÁFICA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildPhotoSelector(),
                const SizedBox(height: 20),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre Completo", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextFormField(controller: _idController, decoration: const InputDecoration(labelText: "Cédula o NIT", border: OutlineInputBorder())),
                
                const SizedBox(height: 20),
                const Divider(),
                
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                  title: const Text("Acepto los Términos y Condiciones"),
                  subtitle: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const TermsEditorScreen())
                      );
                    },
                    child: const Text(
                      "Ver términos legales aquí", 
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading, 
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 20),
                
                // 2. Título y Espacio para la firma
                const Text("FIRMA DEL CLIENTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildSignaturePad(),
                
                // Botón para limpiar firma
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                    label: const Text("Limpiar firma", style: TextStyle(color: Colors.red)),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    disabledBackgroundColor: Colors.grey[300]
                  ),
                  // Ahora validamos que también haya firmado
                  onPressed: (_acceptedTerms && _imageFile != null) ? _saveData : null,
                  child: const Text("PROCEDER A GUARDAR CONTRATO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (_imageFile == null) 
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("* La foto es obligatoria para continuar", style: TextStyle(color: Colors.red, fontSize: 11), textAlign: TextAlign.center),
                  )
              ],
            ),
          ),
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _imageFile == null ? Colors.orange : Colors.green, width: 2),
        ),
        child: _imageFile == null 
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.camera_alt, size: 50, color: Colors.orange), Text("Tomar Foto del Local/Cliente")],
            )
          : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_imageFile!, fit: BoxFit.cover)),
      ),
    );
  }

  // 3. El widget del Pad de Firma
  Widget _buildSignaturePad() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Signature(
          controller: _signatureController,
          height: 180,
          backgroundColor: Colors.grey[50]!,
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    // Validación de firma vacía
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, el cliente debe firmar antes de guardar."))
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 4. Convertir firma a Base64
      final signatureBytes = await _signatureController.toPngBytes();
      final String signatureBase64 = signatureBytes != null ? base64Encode(signatureBytes) : "";

      await DatabaseService().saveClient(
        id: widget.existingClient?.id,
        name: _nameController.text,
        clientId: _idController.text,
        contractType: widget.existingClient?.contractType ?? "Estándar",
        addresses: widget.existingClient?.addresses ?? [],
        signatureBase64: signatureBase64, // Ahora enviamos la firma real
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}