// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  
  // Lista de controladores para manejar múltiples direcciones
  final List<TextEditingController> _addressControllers = [TextEditingController()];

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

  // Métodos para gestionar direcciones
  void _addAddressField() {
    setState(() {
      _addressControllers.add(TextEditingController());
    });
  }

  void _removeAddressField(int index) {
    if (_addressControllers.length > 1) {
      setState(() {
        _addressControllers[index].dispose();
        _addressControllers.removeAt(index);
      });
    }
  }

  void _saveContract() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, el cliente debe firmar")));
      return;
    }

    final signatureBytes = await _signatureController.toPngBytes();
    
    // Extraemos los textos de todos los controladores de dirección
    List<String> addresses = _addressControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

    final Map<String, dynamic> contractData = {
      'client_name': _nameController.text,
      'client_id': _idController.text,
      'addresses': addresses, // Guardamos como lista
      'contract_type': _selectedContractType,
      'date': DateTime.now().toIso8601String(),
      'status': 'Al día', 
      'signature_path': signatureBytes != null ? base64Encode(signatureBytes) : '',
    };

    debugPrint("JSON generado: $contractData");
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contrato guardado exitosamente")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Contrato"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Expanded(
                      child: _buildInput("Dirección ${idx + 1}", entry.value, Icons.location_on),
                    ),
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
              initialValue: _selectedContractType,
              decoration: InputDecoration(
                labelText: "Tipo de Contrato",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _contractTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedContractType = val!),
            ),
            
            const SizedBox(height: 30),
            const Text("Firma del Cliente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Container(
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
            ),
            
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