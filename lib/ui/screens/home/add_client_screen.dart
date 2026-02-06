// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/database_service.dart'; // Asegúrate de tener este import
import '../admin/terms_editor_screen.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final List<TextEditingController> _addressControllers = [TextEditingController()];
  
  File? _imageFile; // Para la foto del cliente
  bool _acceptedTerms = false; // Para los términos legales
  bool _isLoading = false;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String _selectedContractType = 'Servicio Técnico';
  final List<String> _contractTypes = ['Servicio Técnico', 'Alquiler Equipos', 'Consultoría', 'Mantenimiento'];

  @override
  void dispose() {
    _signatureController.dispose();
    _nameController.dispose();
    _idController.dispose();
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- LÓGICA DE FOTO ---
  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
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

  // --- GUARDADO FINAL ---
  void _saveContract() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Es obligatorio tomar una foto del local/cliente")));
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debe aceptar los términos y condiciones")));
      return;
    }
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, el cliente debe firmar")));
      return;
    }

    setState(() => _isLoading = true);

    final signatureBytes = await _signatureController.toPngBytes();
    List<String> addresses = _addressControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

    try {
      // Usamos el DatabaseService que creamos antes
      await DatabaseService().saveClient(
        name: _nameController.text,
        clientId: _idController.text,
        contractType: _selectedContractType,
        addresses: addresses,
        signatureBase64: signatureBytes != null ? base64Encode(signatureBytes) : '',
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contrato guardado en la nube exitosamente")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Contrato"), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SECCIÓN DE FOTO
                const Text("Evidencia Fotográfica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildPhotoBox(),
                
                const SizedBox(height: 25),
                const Text("Datos Principales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInput("Nombre Completo / Empresa", _nameController, Icons.person),
                const SizedBox(height: 15),
                _buildInput("Cédula / NIT", _idController, Icons.badge),
                
                const SizedBox(height: 25),
                
                // SECCIÓN DINÁMICA DE DIRECCIONES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Direcciones de Servicio", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _addAddressField,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Agregar"),
                    ),
                  ],
                ),
                ..._addressControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: _buildInput("Dirección ${idx + 1}", entry.value, Icons.location_on)),
                        if (_addressControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeAddressField(idx),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: _selectedContractType,
                  decoration: InputDecoration(
                    labelText: "Tipo de Contrato",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _contractTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _selectedContractType = val!),
                ),
                
                const SizedBox(height: 30),

                // 2. SECCIÓN DE TÉRMINOS Y CONDICIONES
                _buildTermsSection(),

                const SizedBox(height: 30),
                const Text("Firma del Cliente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                _buildSignaturePad(),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _signatureController.clear(),
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text("Limpiar Firma", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("FINALIZAR Y FIRMAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Widget para la caja de foto
  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _imageFile == null ? Colors.blueAccent : Colors.green, width: 2),
        ),
        child: _imageFile == null 
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.camera_alt, size: 50, color: Colors.blueAccent), Text("Click para tomar foto")],
            )
          : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_imageFile!, fit: BoxFit.cover)),
      ),
    );
  }

  // Widget para los términos legales
  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: CheckboxListTile(
        value: _acceptedTerms,
        onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
        title: const Text("Acepto Términos y Condiciones"),
        subtitle: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsEditorScreen())),
          child: const Text("Leer contrato legal", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
        ),
        controlAffinity: ListTileControlAffinity.leading,
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
          height: 200,
          backgroundColor: Colors.grey[50]!,
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}