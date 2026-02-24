// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTACIÓN AGREGADA PARA LOS FORMATTERS
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  final _amountController = TextEditingController();
  final List<TextEditingController> _addressControllers = [TextEditingController()];
  
  File? _imageFile;
  bool _acceptedTerms = false;
  bool _isLoading = false;

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
    _amountController.dispose();
    for (var controller in _addressControllers) {
      controller.dispose(); 
    }
    super.dispose();
  }

  bool _isValidAmount(String value) {
    if (value.isEmpty) return false;
    final int? val = int.tryParse(value);
    if (val == null) return false;
    return val >= 1000 && val <= 30000 && val % 500 == 0;
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800, 
      imageQuality: 50,
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

  void _saveContract() async {
    final name = _nameController.text.trim();
    final clientId = _idController.text.trim();
    final amountText = _amountController.text.trim();

    if (_imageFile == null) return _showMsg("Es obligatoria la foto de evidencia");
    if (!_acceptedTerms) return _showMsg("Debe aceptar los términos legales");
    if (_signatureController.isEmpty) return _showMsg("El cliente debe firmar el documento");
    if (name.length < 3 || clientId.length < 5) return _showMsg("Datos principales insuficientes");
    if (_selectedContractType == null) return _showMsg("Seleccione un tipo de contrato");
    
    if (!_isValidAmount(amountText)) {
      return _showMsg("El monto debe ser entre 1.000 y 30.000, en múltiplos de 500");
    }

    setState(() => _isLoading = true);

    try {
      final signatureBytes = await _signatureController.toPngBytes();
      
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
        amount: int.parse(amountText), 
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
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isLoading,
            child: SingleChildScrollView(
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
                  const SizedBox(height: 15),
                  _buildAmountInput(),
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
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.indigo),
                        const SizedBox(height: 20),
                        const Text("Guardando Registro...", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Se sincronizará al detectar internet", 
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) => setState(() {}),
      decoration: InputDecoration(
        labelText: "Monto del Contrato",
        hintText: "Eje: 1000, 1500, 2000...",
        prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.indigo),
        helperText: "De 1.000 a 30.000 (Múltiplos de 500)",
        helperStyle: TextStyle(color: _isValidAmount(_amountController.text) ? Colors.green : Colors.blueGrey),
        errorText: _amountController.text.isNotEmpty && !_isValidAmount(_amountController.text) 
            ? "Monto inválido" : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

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
            color: _imageFile == null ? Colors.indigo.withValues(alpha: 0.2) : Colors.green, 
            width: 2, 
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
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final dynamicTypes = snapshot.data!.map((t) => t['title'] as String).toList();
          if (_selectedContractType == null || !dynamicTypes.contains(_selectedContractType)) {
            _selectedContractType = dynamicTypes.first;
          }
          return DropdownButtonFormField<String>(
            initialValue: _selectedContractType,
            decoration: InputDecoration(
              labelText: "Seleccionar Contrato",
              filled: true, 
              fillColor: Colors.grey[100],
              prefixIcon: const Icon(Icons.article_outlined, color: Colors.indigo),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: dynamicTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _selectedContractType = val),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        return const Text("No hay plantillas disponibles", style: TextStyle(color: Colors.red));
      },
    );
  }
    
  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
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