// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../../data/models/client_model.dart';
import '../../../services/database_service.dart';
import '../admin/terms_editor_screen.dart';

/// Formulario interactivo para la creación y edición de clientes.
/// 
/// Gestiona la captura de datos personales, múltiples direcciones, toma de fotografía,
/// selección de tipo de contrato dinámico y recolección de firma digital.
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

  /// Inicializa los campos del formulario con datos existentes si se trata de una edición.
  void _initializeFields() {
    _nameController = TextEditingController(text: widget.existingClient?.name ?? '');
    _idController = TextEditingController(text: widget.existingClient?.clientId ?? '');

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
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE GESTIÓN DE DIRECCIONES ---

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

  // --- LÓGICA DE CAPTURA DE MEDIOS ---

  /// Activa la cámara del dispositivo para capturar la fotografía del cliente.
  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 30, // Calidad optimizada para Firebase Storage
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  /// Procesa y guarda la información del cliente en Firestore.
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validación de firma obligatoria para nuevos registros
    if (_signatureController.isEmpty && widget.existingClient == null) {
      _showSnackBar("Falta la firma del cliente", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      String signatureBase64 = widget.existingClient?.signatureBase64 ?? "";
      
      // Conversión de firma de trazos a imagen Base64
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
        contractType: _selectedContractType ?? "Sin especificar",
        addresses: addresses,
        signatureBase64: signatureBase64,
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      if (mounted) {
        _showSnackBar("¡Datos guardados correctamente!", isError: false);
        _handleNavigationReturn();
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error al guardar: $e", isError: true);
      // ignore: avoid_print
      print("Error detallado: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Gestión inteligente de navegación post-guardado.
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
      // Usamos Stack para encimar el cargador sobre el formulario
      body: Stack(
        children: [
          // 1. El Formulario
          IgnorePointer(
            ignoring: _isLoading, // Bloquea todos los inputs si está cargando
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPhotoSelector(),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, "Nombre Completo"),
                  const SizedBox(height: 15),
                  _buildTextField(_idController, "Cédula o NIT"),
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

          // 2. El Overlay de Bloqueo (Solo se ve cuando _isLoading es true)
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4), // Oscurece el fondo
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
                      const Text(
                        "Guardando datos...",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Sincronización offline activa",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  // --- COMPONENTES DE INTERFAZ ---

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, 
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Este campo es obligatorio" : null,
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
            const Text("DIRECCIONES DE SERVICIO", style: TextStyle(fontWeight: FontWeight.bold)), 
            IconButton(onPressed: _addAddressField, icon: const Icon(Icons.add_circle, color: Colors.blueAccent))
          ]
        ),
        ..._addressControllers.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: [
              Expanded(child: TextFormField(
                controller: e.value, 
                decoration: const InputDecoration(hintText: "Escriba la dirección", border: OutlineInputBorder())
              )),
              IconButton(onPressed: () => _removeAddressField(e.key), icon: const Icon(Icons.delete, color: Colors.red))
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        color: Colors.blue.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3))
      ),
      child: CheckboxListTile(
        value: _acceptedTerms,
        onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
        title: const Text("Acepto términos y condiciones", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen())),
          child: const Text("Leer contrato legal completo", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12)),
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
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text("Limpiar Firma")
    )
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity, 
    height: 50,
    child: ElevatedButton(
      onPressed: (_acceptedTerms) ? _saveData : null, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      child: const Text("GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
    )
  );
}