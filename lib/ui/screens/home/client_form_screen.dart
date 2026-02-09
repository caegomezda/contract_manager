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

  late TextEditingController _nameController;
  late TextEditingController _idController;
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
    } else {
      _selectedContractType = null; // Se establecerá dinámicamente al cargar los datos de Firebase
      _acceptedTerms = false;
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

Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Si es un cliente nuevo, la firma es obligatoria. 
    // Si es una edición, puede usar la que ya existe.
    if (_signatureController.isEmpty && widget.existingClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falta la firma del cliente")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      String signatureBase64 = widget.existingClient?.signatureBase64 ?? "";
      
      // Si el usuario dibujó algo nuevo en el pad, procesamos esa nueva firma
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

      // Llamada al servicio para guardar/actualizar
      await DatabaseService().saveClient(
        id: widget.existingClient?.id,
        manualWorkerId: widget.existingClient?.workerId,
        // manualWorkerName: widget.existingClient?.workerName,
        name: _nameController.text.trim(),
        clientId: _idController.text.trim(),
        contractType: _selectedContractType ?? "Sin especificar",
        addresses: addresses,
        signatureBase64: signatureBase64,
        photoFile: _imageFile,
        termsAccepted: _acceptedTerms,
      );

      if (mounted) {
        // 1. Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green, 
            content: Text("¡Datos actualizados correctamente!"),
            duration: Duration(seconds: 2),
          ),
        );

        // 2. VOLVER AL LISTADO:
        // Navigator.pop quita la pantalla actual y vuelve a la anterior (el listado)
        // LÓGICA DE RETORNO INTELIGENTE
        if (widget.existingClient != null) {
          // Si estamos editando, queremos saltar el "Detalle" y volver al listado
          // Esto cierra el formulario Y la pantalla de detalle que estaba debajo
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        } else {
          // Si es un cliente nuevo, un pop normal es suficiente
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red, 
            content: Text("Error al guardar: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingClient == null ? "Nuevo Cliente" : "Actualizar Cliente")),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPhotoSelector(),
            const SizedBox(height: 20),
            _buildTextField(_nameController, "Nombre Completo"),
            const SizedBox(height: 15),
            _buildTextField(_idController, "Cédula o NIT", isId: true),
            const SizedBox(height: 20),
            _buildAddressSection(),
            const SizedBox(height: 20),
            _buildContractDropdown(),
            const SizedBox(height: 10),
            _buildTermsTile(),
            const SizedBox(height: 20),
            const Text("FIRMA DEL CLIENTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            _buildSignaturePad(),
            _buildSignatureClearButton(),
            const SizedBox(height: 30),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Resumidos para claridad) ---
  Widget _buildTextField(TextEditingController controller, String label, {bool isId = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (val) => (val == null || val.isEmpty) ? "Campo obligatorio" : null,
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
          border: Border.all(color: _imageFile == null && widget.existingClient == null ? Colors.orange : Colors.green)
        ),
        child: _imageFile != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
          : const Center(child: Icon(Icons.camera_alt, size: 40, color: Colors.grey)),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("DIRECCIONES"), 
        IconButton(onPressed: _addAddressField, icon: const Icon(Icons.add_circle))
      ]),
      ..._addressControllers.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(children: [
          Expanded(child: TextFormField(controller: e.value, decoration: const InputDecoration(border: OutlineInputBorder()))),
          IconButton(onPressed: () => _removeAddressField(e.key), icon: const Icon(Icons.delete, color: Colors.red))
        ]),
      ))
    ]);
  }

  Widget _buildContractDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getTemplatesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        // Extraemos solo los títulos de las plantillas de Firebase
        List<String> dynamicContractTypes = snapshot.data!
            .map((t) => t['title'] as String)
            .toList();

        // Validación para evitar errores si el valor seleccionado no existe en la nueva lista
        if (_selectedContractType == null || !dynamicContractTypes.contains(_selectedContractType)) {
          _selectedContractType = dynamicContractTypes.isNotEmpty ? dynamicContractTypes.first : null;
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedContractType,
          decoration: InputDecoration(
            labelText: "Tipo de Contrato (Desde Firebase)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: dynamicContractTypes.map((t) => DropdownMenuItem(
            value: t, 
            child: Text(t)
          )).toList(),
          onChanged: (val) => setState(() => _selectedContractType = val),
        );
      },
    );
  }

  Widget _buildTermsTile() {
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

  Widget _buildSignatureClearButton() => Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _signatureController.clear(), child: const Text("Limpiar")));

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity, 
    child: ElevatedButton(
      onPressed: (_acceptedTerms) ? _saveData : null, 
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      child: const Text("GUARDAR", style: TextStyle(color: Colors.white))
    )
  );
}