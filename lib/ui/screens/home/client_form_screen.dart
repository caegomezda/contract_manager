// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
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
  
  // 1. Inicialización correcta de controladores
  late TextEditingController _nameController;
  late TextEditingController _idController;
  
  File? _imageFile;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _selectedContractType;

  // 2. Controlador de la firma
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    // Inicializamos controladores con datos existentes o vacíos
    _nameController = TextEditingController(text: widget.existingClient?.name ?? '');
    _idController = TextEditingController(text: widget.existingClient?.clientId ?? '');
    
    // Si renovamos, precargamos el tipo de contrato actual
    if (widget.existingClient != null) {
      _selectedContractType = widget.existingClient!.contractType;
      _acceptedTerms = widget.existingClient!.termsAccepted;
    }
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
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 30,
    );
    
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingClient == null ? "Nuevo Cliente" : "Renovar Contrato"),
        elevation: 0,
      ),
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
                
                // Campos de texto con validación básica
                TextFormField(
                  controller: _nameController, 
                  decoration: const InputDecoration(labelText: "Nombre Completo", border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? "El nombre es obligatorio" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _idController, 
                  decoration: const InputDecoration(labelText: "Cédula o NIT", border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.length < 5) ? "ID demasiado corto" : null,
                ),
                
                const SizedBox(height: 20),
                
                // DROPDOWN CORREGIDO (Sin el error de 'value' o 'initialValue')
                DropdownButtonFormField<String>(
                  initialValue: _selectedContractType, 
                  decoration: const InputDecoration(
                    labelText: "Tipo de Contrato",
                    border: OutlineInputBorder(),
                  ),
                  items: ['Servicio Estándar', 'Servicio Premium', 'Mantenimiento']
                      .map((String type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedContractType = newValue;
                    });
                  },
                  validator: (value) => value == null ? "Seleccione un tipo de contrato" : null,
                ),
                
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
                const Text("FIRMA DEL CLIENTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildSignaturePad(),
                
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
                  // Botón habilitado solo si acepta términos y hay foto
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
    // 1. Validar Formulario (Nombre e ID)
    if (!_formKey.currentState!.validate()) return;

    // 2. Validar firma no vacía
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, el cliente debe firmar antes de continuar."))
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 3. Procesar firma a Base64
      final signatureBytes = await _signatureController.toPngBytes();
      final String signatureBase64 = signatureBytes != null ? base64Encode(signatureBytes) : "";

      // 4. Guardar en Firestore vía DatabaseService
      await DatabaseService().saveClient(
        id: widget.existingClient?.id,
        name: _nameController.text.trim(),
        clientId: _idController.text.trim(),
        // PUNTO 5: Usamos el contrato seleccionado actualmente (permite cambios al renovar)
        contractType: _selectedContractType ?? "Servicio Estándar",
        addresses: widget.existingClient?.addresses ?? [],
        signatureBase64: signatureBase64,
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Contrato guardado exitosamente"))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al guardar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error al guardar: $e"))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}