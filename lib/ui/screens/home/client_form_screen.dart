// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTANTE para FilteringTextInputFormatter
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

  // Controladores de Texto
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  List<TextEditingController> _addressControllers = [];

  // Estado del Formulario
  File? _imageFile;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _selectedContractType;

  // Controlador de Firma Digital
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.existingClient?.name ?? '');
    _idController = TextEditingController(text: widget.existingClient?.clientId ?? '');
    _emailController = TextEditingController(text: widget.existingClient?.email ?? '');
    _phoneController = TextEditingController(text: widget.existingClient?.phone ?? '');
    
    // Inicializar monto: si es 0 o null, poner vacío para que el hint sea visible
    String initialAmount = widget.existingClient?.monto != null && widget.existingClient!.monto > 0 
        ? widget.existingClient!.monto.toInt().toString() 
        : "";
    _amountController = TextEditingController(text: initialAmount);

    final existingAddresses = widget.existingClient?.addresses ?? [];
    if (existingAddresses.isEmpty) {
      _addressControllers = [TextEditingController()];
    } else {
      _addressControllers = existingAddresses
          .map((addr) => TextEditingController(text: addr))
          .toList();
    }

    if (widget.existingClient != null) {
      _selectedContractType = widget.existingClient!.contractType;
      _acceptedTerms = widget.existingClient!.termsAccepted;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  // --- VALIDACIONES ---
  
  bool _isValidAmount(String text) {
    if (text.isEmpty) return false;
    final numValue = int.tryParse(text);
    return numValue != null && numValue > 0 && numValue % 500 == 0;
  }

  // --- LÓGICA DE DIRECCIONES ---

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

  // --- LÓGICA DE CAPTURA ---

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 30, 
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveData() async {
    // Validación de monto antes de proceder
    if (!_isValidAmount(_amountController.text)) {
      _showSnackBar("El monto debe ser múltiplo de 500", isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    if (_signatureController.isEmpty && widget.existingClient == null) {
      _showSnackBar("Falta la firma del cliente", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      String signatureBase64 = widget.existingClient?.signatureBase64 ?? "";
      
      if (_signatureController.isNotEmpty) {
        final signatureBytes = await _signatureController.toPngBytes();
        if (signatureBytes != null) {
          signatureBase64 = base64Encode(signatureBytes);
        }
      }

      final List<String> addresses = _addressControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await DatabaseService().saveClient(
        id: widget.existingClient?.id,
        manualWorkerId: widget.existingClient?.workerId,
        name: _nameController.text.trim(),
        clientId: _idController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        contractType: _selectedContractType ?? "Sin especificar",
        addresses: addresses,
        signatureBase64: signatureBase64,
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      if (mounted) {
        _showSnackBar("¡Datos guardados correctamente!", isError: false);
        _handleNavigationReturn();
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error al guardar: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleNavigationReturn() {
    if (widget.existingClient != null) {
      int count = 0;
      Navigator.of(context).popUntil((_) => count++ >= 2);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green, 
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingClient == null ? "Nuevo Cliente" : "Actualizar Cliente"),
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isLoading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPhotoSelector(),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, "Nombre Completo", Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildTextField(_idController, "Cédula o NIT", Icons.badge_outlined),
                  const SizedBox(height: 15),
                  _buildTextField(_emailController, "Correo Electrónico", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildTextField(_phoneController, "Número de Celular", Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _buildAmountInput(), // USANDO EL NUEVO COMPONENTE CON RESTRICCIÓN
                  const SizedBox(height: 20),
                  _buildAddressSection(),
                  const SizedBox(height: 20),
                  _buildContractDropdown(),
                  const SizedBox(height: 10),
                  _buildTermsTile(),
                  const SizedBox(height: 20),
                  const Text("FIRMA DEL CLIENTE", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildSignaturePad(),
                  _buildSignatureClearButton(),
                  const SizedBox(height: 30),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- COMPONENTES DE INTERFAZ ---

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Este campo es obligatorio" : null,
    );
  }

  Widget _buildAmountInput() {
    bool isValid = _isValidAmount(_amountController.text);
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) => setState(() {}),
      decoration: InputDecoration(
        labelText: "Monto del Contrato",
        hintText: "Ej: 1000, 5000, 10000...",
        prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.indigo),
        helperText: "Múltiplos de 500",
        helperStyle: TextStyle(color: isValid ? Colors.green : Colors.blueGrey),
        errorText: _amountController.text.isNotEmpty && !isValid 
            ? "El monto debe ser múltiplo de 500" : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "Ingrese un monto";
        if (!isValid) return "Monto no permitido";
        return null;
      },
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100], 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _imageFile == null && widget.existingClient == null 
              ? Colors.orange 
              : Colors.green
          )
        ),
        child: _imageFile != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
          : (widget.existingClient?.photoUrl != null) 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12), 
                child: Image.memory(base64Decode(widget.existingClient!.photoUrl!), fit: BoxFit.cover)
              )
            : const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  Text("Capturar Foto", style: TextStyle(color: Colors.grey)),
                ],
              )),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            const Text("DIRECCIONES DE SERVICIO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)), 
            IconButton(onPressed: _addAddressField, icon: const Icon(Icons.add_circle, color: Colors.indigo))
          ]
        ),
        ..._addressControllers.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: [
              Expanded(child: TextFormField(
                controller: e.value, 
                decoration: InputDecoration(
                  hintText: "Escriba la dirección", 
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                )
              )),
              const SizedBox(width: 5),
              IconButton(onPressed: () => _removeAddressField(e.key), icon: const Icon(Icons.delete_outline, color: Colors.redAccent))
            ]
          ),
        ))
      ]
    );
  }

  Widget _buildContractDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getTemplatesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        List<String> dynamicContractTypes = snapshot.data!
            .map((t) => t['title'] as String)
            .toList();

        if (_selectedContractType == null || !dynamicContractTypes.contains(_selectedContractType)) {
          _selectedContractType = dynamicContractTypes.isNotEmpty ? dynamicContractTypes.first : null;
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedContractType,
          decoration: InputDecoration(
            labelText: "Tipo de Contrato",
            prefixIcon: const Icon(Icons.description_outlined, color: Colors.indigo),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: dynamicContractTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) => setState(() => _selectedContractType = val),
        );
      },
    );
  }

  Widget _buildTermsTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1))
      ),
      child: CheckboxListTile(
        value: _acceptedTerms,
        activeColor: Colors.indigo,
        onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
        title: const Text("Acepto términos y condiciones", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen())),
          child: const Text("Leer contrato legal completo", style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline, fontSize: 12)),
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

  Widget _buildSignatureClearButton() => Align(
    alignment: Alignment.centerRight, 
    child: TextButton.icon(
      onPressed: () => _signatureController.clear(), 
      icon: const Icon(Icons.refresh, size: 16, color: Colors.indigo),
      label: const Text("Limpiar Firma", style: TextStyle(color: Colors.indigo))
    )
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity, 
    height: 55,
    child: ElevatedButton(
      onPressed: (_acceptedTerms && !_isLoading) ? _saveData : null, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        disabledBackgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text("GUARDAR CLIENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
    )
  );

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.indigo),
              const SizedBox(height: 20),
              const Text("Guardando datos...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text("Sincronización offline activa", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}