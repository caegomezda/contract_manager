// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // IMPORTANTE
import '../../../services/database_service.dart';
import '../admin/terms_editor_screen.dart';

class AddClientScreen extends StatefulWidget {
  final String? adminAssignId;
  final String? adminAssignName;
  const AddClientScreen({super.key, this.adminAssignId, this.adminAssignName});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final List<TextEditingController> _addressControllers = [TextEditingController()];
  
  File? _imageFile;
  bool _acceptedTerms = false;
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
    for (var controller in _addressControllers) {controller.dispose(); }
    super.dispose();
  }

  // --- LÓGICA DE MEDIA ---
  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 600, maxHeight: 600, imageQuality: 30,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _addAddressField() => setState(() => _addressControllers.add(TextEditingController()));
  
  void _removeAddressField(int index) {
    if (_addressControllers.length > 1) {
      setState(() {
        _addressControllers[index].dispose();
        _addressControllers.removeAt(index);
      });
    }
  }

  // --- GUARDADO FINAL OPTIMIZADO ---
  void _saveContract() async {
    final name = _nameController.text.trim();
    final clientId = _idController.text.trim();

    // Validaciones rápidas
    if (_imageFile == null) return _showMsg("Es obligatoria la foto de evidencia");
    if (!_acceptedTerms) return _showMsg("Debe aceptar los términos");
    if (_signatureController.isEmpty) return _showMsg("El cliente debe firmar");
    if (name.length < 3 || clientId.length < 5) return _showMsg("Datos principales incompletos");

    setState(() => _isLoading = true);

    try {
      final signatureBytes = await _signatureController.toPngBytes();
      List<String> addresses = _addressControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

      // LLAMADA AL SERVICIO (El servicio ya usa FirebaseAuth interno, pero aseguramos datos)
      await DatabaseService().saveClient(
        manualWorkerId: widget.adminAssignId,    
        manualWorkerName: widget.adminAssignName,
        name: _nameController.text.trim(),
        clientId: _idController.text.trim(),
        contractType: _selectedContractType,
        addresses: addresses,
        signatureBase64: signatureBytes != null ? base64Encode(signatureBytes) : '',
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      Navigator.pop(context);
      _showMsg("Contrato vinculado y guardado exitosamente");
    } catch (e) {
      _showMsg("Error al guardar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Nuevo Contrato"), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Evidencia Fotográfica"),
                _buildPhotoBox(),
                
                const SizedBox(height: 25),
                _sectionTitle("Datos Principales"),
                _buildInput("Nombre Completo / Empresa", _nameController, Icons.person),
                const SizedBox(height: 15),
                _buildInput("Cédula / NIT", _idController, Icons.badge),
                
                const SizedBox(height: 25),
                _buildAddressHeader(),
                ..._buildAddressList(),

                const SizedBox(height: 20),
                _buildContractDropdown(),
                
                const SizedBox(height: 30),
                _buildTermsSection(),

                const SizedBox(height: 30),
                _sectionTitle("Firma del Cliente"),
                _buildSignaturePad(),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    label: const Text("Limpiar Firma", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
    );
  }

  // --- COMPONENTES MODULARES (OPTIMIZACIÓN) ---

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPhotoBox() {
    return InkWell(
      onTap: _takePhoto,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _imageFile == null ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.green, width: 2),
        ),
        child: _imageFile == null 
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.camera_alt, size: 40, color: Colors.blueAccent), Text("Tomar foto del local")],
            )
          : ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_imageFile!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildAddressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Al usar Expanded, el texto respetará el espacio del icono y no causará overflow
        const Expanded(
          child: Text(
            "Direcciones de Servicio", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis, // Opcional: añade "..." si el texto es excesivamente largo
          ),
        ),
        IconButton(
          onPressed: _addAddressField, 
          icon: const Icon(Icons.add_circle, color: Colors.blueAccent)
        ),
      ],
    );
  }

  List<Widget> _buildAddressList() {
    return _addressControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: _buildInput("Dirección ${idx + 1}", entry.value, Icons.location_on)),
            if (_addressControllers.length > 1)
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _removeAddressField(idx)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildContractDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedContractType,
      decoration: InputDecoration(
        labelText: "Tipo de Contrato",
        filled: true, fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: _contractTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (val) => setState(() => _selectedContractType = val!),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        value: _acceptedTerms,
        onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
        title: const Text("Acepto términos y condiciones", style: TextStyle(fontSize: 14)),
        subtitle: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen())),
          child: const Text("Ver contrato legal", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12)),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSignaturePad() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Signature(controller: _signatureController, backgroundColor: Colors.grey[50]!),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveContract,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0
        ),
        child: const Text("FINALIZAR Y GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}