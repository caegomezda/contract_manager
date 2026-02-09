// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/database_service.dart';
import '../admin/terms_editor_screen.dart';

/// Pantalla para registrar un nuevo cliente y capturar su firma/foto.
/// Permite la asignación manual por parte de un Admin o captura automática por el Worker.
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

  // Controlador para el pad de firma
  late final SignatureController _signatureController;

  String? _selectedContractType;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

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

  // --- LÓGICA DE CAPTURA DE IMAGEN ---
  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800, // Un poco más de resolución para legibilidad
      maxHeight: 800, 
      imageQuality: 50, // Balance entre peso y nitidez
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

  // --- PERSISTENCIA EN FIREBASE ---
  void _saveContract() async {
    final name = _nameController.text.trim();
    final clientId = _idController.text.trim();

    // Validaciones de seguridad
    if (_imageFile == null) return _showMsg("Es obligatoria la foto de evidencia");
    if (!_acceptedTerms) return _showMsg("Debe aceptar los términos legales");
    if (_signatureController.isEmpty) return _showMsg("El cliente debe firmar el documento");
    if (name.length < 3 || clientId.length < 5) return _showMsg("Datos principales insuficientes");
    if (_selectedContractType == null) return _showMsg("Seleccione un tipo de contrato");

    setState(() => _isLoading = true);

    try {
      // Exportar firma a bytes
      final signatureBytes = await _signatureController.toPngBytes();
      
      // Limpiar direcciones vacías
      List<String> addresses = _addressControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (addresses.isEmpty) {
        setState(() => _isLoading = false);
        return _showMsg("Debe ingresar al menos una dirección");
      }

      await DatabaseService().saveClient(
        manualWorkerId: widget.adminAssignId,    
        manualWorkerName: widget.adminAssignName,
        name: name,
        clientId: clientId,
        contractType: _selectedContractType!, 
        addresses: addresses,
        signatureBase64: signatureBytes != null ? base64Encode(signatureBytes) : '',
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      if (mounted) {
        Navigator.pop(context);
        _showMsg("✅ Contrato guardado exitosamente");
      }
    } catch (e) {
      _showMsg("❌ Error al guardar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nuevo Registro"), 
        elevation: 0, 
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black
      ),
      body: _isLoading 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Subiendo información...")],
          ))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Evidencia Fotográfica"),
                _buildPhotoBox(),
                
                const SizedBox(height: 25),
                _sectionTitle("Datos del Cliente"),
                _buildInput("Nombre o Razón Social", _nameController, Icons.business),
                const SizedBox(height: 15),
                _buildInput("Identificación (NIT/CC)", _idController, Icons.badge),
                
                const SizedBox(height: 25),
                _buildAddressHeader(),
                ..._buildAddressList(),

                const SizedBox(height: 20),
                _buildContractDropdown(),
                
                const SizedBox(height: 30),
                _buildTermsSection(),

                const SizedBox(height: 30),
                _sectionTitle("Firma Autorizada"),
                _buildSignaturePad(),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    label: const Text("Reintentar Firma", style: TextStyle(color: Colors.orange)),
                  ),
                ),
                
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // --- COMPONENTES VISUALES ---

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), 
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1)),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPhotoBox() {
    return InkWell(
      onTap: _takePhoto,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _imageFile == null ? Colors.indigo.withOpacity(0.2) : Colors.green, 
            width: 2, 
            style: _imageFile == null ? BorderStyle.solid : BorderStyle.solid
          ),
        ),
        child: _imageFile == null 
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add_a_photo_outlined, size: 45, color: Colors.indigo), Text("Capturar local o aviso")],
            )
          : ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_imageFile!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildAddressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle("Sedes / Direcciones"),
        IconButton(
          onPressed: _addAddressField, 
          icon: const Icon(Icons.add_circle_outline, color: Colors.indigo)
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
            Expanded(child: _buildInput("Dirección #${idx + 1}", entry.value, Icons.location_on_outlined)),
            if (_addressControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), 
                onPressed: () => _removeAddressField(idx)
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildContractDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getTemplatesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("⚠️ No hay tipos de contrato definidos.", style: TextStyle(color: Colors.red));
        }

        final dynamicTypes = snapshot.data!.map((t) => t['title'] as String).toList();
        _selectedContractType ??= dynamicTypes.first;

        return DropdownButtonFormField<String>(
          initialValue: _selectedContractType,
          decoration: InputDecoration(
            labelText: "Seleccionar Plantilla de Contrato",
            filled: true, 
            fillColor: Colors.grey[100],
            prefixIcon: const Icon(Icons.article_outlined, color: Colors.indigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: dynamicTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) => setState(() => _selectedContractType = val),
        );
      },
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12)
      ),
      child: CheckboxListTile(
        value: _acceptedTerms,
        onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
        title: const Text("El cliente acepta los términos y condiciones", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen())),
          child: const Text("Leer contrato legal completo", style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline, fontSize: 12)),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.indigo,
      ),
    );
  }

  Widget _buildSignaturePad() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Signature(
          controller: _signatureController, 
          backgroundColor: Colors.transparent
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveContract,
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        label: const Text("GUARDAR REGISTRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2
        ),
      ),
    );
  }
}