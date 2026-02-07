// lib/ui/screens/admin/terms_editor_screen.dart

import 'package:flutter/material.dart';
import '../../../services/database_service.dart';

class TermsEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? existingTemplate;
  const TermsEditorScreen({super.key, this.existingTemplate});

  @override
  State<TermsEditorScreen> createState() => _TermsEditorScreenState();
}

class _TermsEditorScreenState extends State<TermsEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      _titleController.text = widget.existingTemplate!['title'] ?? '';
      _bodyController.text = widget.existingTemplate!['body'] ?? '';
    }
  }

  void _save() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor rellena todos los campos")),
      );
      return;
    }
    
    try {
      // Llamada al servicio que ya definimos en DatabaseService
      await DatabaseService().saveContractTemplate(
        _titleController.text.trim(), 
        _bodyController.text.trim()
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Plantilla actualizada correctamente en la nube"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Plantilla Legal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Nombre del Contrato (ej: Servicio Estándar)",
                helperText: "El ID se generará automáticamente",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Cuerpo del Contrato. Usa {{nombre}}, {{id}}, {{contrato}} y {{fecha}} como variables.",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _bodyController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Escribe aquí los términos legales...",
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("GUARDAR PLANTILLA EN NUBE"),
            )
          ],
        ),
      ),
    );
  }
}