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
  final List<String> _contractTypes = [
    'Servicio Técnico',
    'Alquiler Equipos',
    'Consultoría',
    'Mantenimiento'
  ];

  // Controladores principales
  late TextEditingController _nameController;
  late TextEditingController _idController;
  // Corrección: Lista de controladores para direcciones dinámicas
  List<TextEditingController> _addressControllers = [];

  File? _imageFile;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _selectedContractType;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    // Inicialización de controladores de texto
    _nameController = TextEditingController(text: widget.existingClient?.name ?? '');
    _idController = TextEditingController(text: widget.existingClient?.clientId ?? '');

    // Inicialización dinámica de direcciones (Corrección Error Undefined Name)
    final existingAddresses = widget.existingClient?.addresses ?? [];
    if (existingAddresses.isEmpty) {
      _addressControllers = [TextEditingController()];
    } else {
      _addressControllers = existingAddresses
          .map((addr) => TextEditingController(text: addr))
          .toList();
    }

    // Lógica de contrato inicial
    if (widget.existingClient != null) {
      _selectedContractType = widget.existingClient!.contractType;
      _acceptedTerms = widget.existingClient!.termsAccepted;
    } else {
      _selectedContractType = _contractTypes.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    // Limpieza de controladores dinámicos
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  void _addAddressField() {
    setState(() => _addressControllers.add(TextEditingController()));
  }

  void _removeAddressField(int index) {
    if (_addressControllers.length > 1) {
      setState(() {
        _addressControllers[index].dispose();
        _addressControllers.removeAt(index);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 30,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
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
                  const Text("EVIDENCIA FOTOGRÁFICA",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildPhotoSelector(),
                  const SizedBox(height: 20),
                  
                  _buildTextField(_nameController, "Nombre Completo"),
                  const SizedBox(height: 15),
                  _buildTextField(_idController, "Cédula o NIT", isId: true),
                  
                  const SizedBox(height: 20),
                  _buildAddressSection(),
                  
                  const SizedBox(height: 20),
                  _buildContractDropdown(),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  _buildTermsTile(),

                  const SizedBox(height: 20),
                  const Text("FIRMA DEL CLIENTE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildSignaturePad(),
                  
                  _buildSignatureClearButton(),

                  const SizedBox(height: 30),
                  _buildSaveButton(),
                  
                  if (_imageFile == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("* La foto es obligatoria para continuar",
                          style: TextStyle(color: Colors.red, fontSize: 11), textAlign: TextAlign.center),
                    )
                ],
              ),
            ),
    );
  }

  // --- WIDGETS MODULARIZADOS ---

  Widget _buildTextField(TextEditingController controller, String label, {bool isId = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) {
        if (value == null || value.isEmpty) return "Campo obligatorio";
        if (isId && value.length < 5) return "ID demasiado corto";
        return null;
      },
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("DIRECCIONES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            TextButton.icon(onPressed: _addAddressField, icon: const Icon(Icons.add), label: const Text("Añadir"))
          ],
        ),
        ..._addressControllers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: "Dirección ${entry.key + 1}", border: const OutlineInputBorder()),
                  ),
                ),
                if (_addressControllers.length > 1)
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeAddressField(entry.key)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContractDropdown() {
    return DropdownButtonFormField<String>(
      // Corrección de acceso a widget y lógica de valor inicial
      initialValue: _selectedContractType != null && _contractTypes.contains(_selectedContractType)
          ? _selectedContractType
          : _contractTypes.first,
      decoration: InputDecoration(
        labelText: "Tipo de Contrato",
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: _contractTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (val) => setState(() => _selectedContractType = val),
    );
  }

  Widget _buildTermsTile() {
    return CheckboxListTile(
      value: _acceptedTerms,
      onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
      title: const Text("Acepto los Términos y Condiciones"),
      subtitle: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsEditorScreen())),
        child: const Text("Ver términos legales aquí",
            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
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
          // Actualizado: withValues en lugar de withOpacity
          border: Border.all(color: _imageFile == null ? Colors.orange : Colors.green, width: 2),
        ),
        child: _imageFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.camera_alt, size: 50, color: Colors.orange), Text("Tomar Foto")],
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

  Widget _buildSignatureClearButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _signatureController.clear(),
        icon: const Icon(Icons.clear, color: Colors.red, size: 18),
        label: const Text("Limpiar firma", style: TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 15),
        disabledBackgroundColor: Colors.grey[300],
      ),
      onPressed: (_acceptedTerms && _imageFile != null) ? _saveData : null,
      child: const Text("GUARDAR CONTRATO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta la firma del cliente")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final signatureBytes = await _signatureController.toPngBytes();
      final String signatureBase64 = signatureBytes != null ? base64Encode(signatureBytes) : "";
      final List<String> addresses = _addressControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

      await DatabaseService().saveClient(
        id: widget.existingClient?.id,
        name: _nameController.text.trim(),
        clientId: _idController.text.trim(),
        contractType: _selectedContractType ?? _contractTypes.first,
        addresses: addresses,
        signatureBase64: signatureBase64,
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Éxito")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}