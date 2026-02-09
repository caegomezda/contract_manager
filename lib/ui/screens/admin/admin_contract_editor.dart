// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../services/database_service.dart'; // Asegúrate de que la ruta sea correcta

class AdminContractEditor extends StatefulWidget {
  final bool isReadOnly;
  final Map<String, dynamic>? initialData;

  const AdminContractEditor({super.key, this.isReadOnly = false, this.initialData});

  @override
  State<AdminContractEditor> createState() => _AdminContractEditorState();
}

class _AdminContractEditorState extends State<AdminContractEditor> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData?['title'] ?? '');
    _bodyController = TextEditingController(text: widget.initialData?['body'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // LÓGICA DE GUARDADO REAL EN FIREBASE
  Future<void> _saveTemplate() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título y el cuerpo son obligatorios")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Llamamos al servicio (usamos el ID si estamos editando uno existente)
      await DatabaseService().saveTemplate(
        id: widget.initialData?['id'], 
        title: title,
        body: body,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Plantilla guardada exitosamente en la base de datos"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Error al guardar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _insertHotkey(String tag) {
    if (widget.isReadOnly) return;
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    int start = selection.start != -1 ? selection.start : text.length;
    int end = selection.end != -1 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, tag);
    _bodyController.text = newText;
    _bodyController.selection = TextSelection.collapsed(offset: start + tag.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "Detalle del Contrato" : "Editor de Contrato"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  enabled: !widget.isReadOnly,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Nombre del Contrato (Ej: Servicio Técnico)",
                    isDense: true,
                    border: widget.isReadOnly ? InputBorder.none : const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                if (!widget.isReadOnly) ...[
                  const Text("Variables Dinámicas (Haz clic para insertar)", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _tagChip("{{nombre}}", "Nombre"),
                        _tagChip("{{id}}", "ID/Cédula"),
                        _tagChip("{{direcciones}}", "Sedes"),
                        _tagChip("{{fecha}}", "Fecha"),
                        _tagChip("{{firma}}", "Firma"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                const Text("Cuerpo del Contrato", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const Divider(),

                TextField(
                  controller: _bodyController,
                  enabled: !widget.isReadOnly,
                  maxLines: null,
                  minLines: 15,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: "Escribe el contenido legal aquí usando las {{variables}}...",
                    filled: widget.isReadOnly,
                    fillColor: widget.isReadOnly ? Colors.grey[50] : Colors.white,
                    border: widget.isReadOnly ? InputBorder.none : const OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 24),

                if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTemplate,
                      icon: const Icon(Icons.cloud_upload, color: Colors.white),
                      label: const Text("GUARDAR", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                
                if (widget.isReadOnly)
                  const Center(
                    child: Text("Modo lectura: No se permiten cambios.",
                      style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _tagChip(String tag, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _insertHotkey(tag),
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1), // Corrección de deprecación
        labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
        side: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}