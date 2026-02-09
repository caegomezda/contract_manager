// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../../services/database_service.dart';

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

  Future<void> _saveTemplate() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showSnackBar("El título y el cuerpo son obligatorios", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseService().saveTemplate(
        id: widget.initialData?['id'], 
        title: title,
        body: body,
      );

      if (mounted) {
        _showSnackBar("✅ Plantilla guardada exitosamente");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error al guardar: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  void _insertHotkey(String tag) {
    if (widget.isReadOnly) return;
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    // Si no hay selección previa, insertamos al final
    int start = selection.start != -1 ? selection.start : text.length;
    int end = selection.end != -1 ? selection.end : text.length;
    
    final newText = text.replaceRange(start, end, tag);
    _bodyController.text = newText;
    
    // Reposicionamos el cursor justo después del tag insertado
    _bodyController.selection = TextSelection.collapsed(offset: start + tag.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "Detalle del Contrato" : "Editor"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveTemplate,
            )
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Configuración General", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  enabled: !widget.isReadOnly,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Nombre del Contrato",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                
                if (!widget.isReadOnly) ...[
                  const Text("Variables Dinámicas", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
                  const Text("Toca para insertar en la posición del cursor:", 
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap( // Wrap es mejor que Row para pantallas pequeñas
                    spacing: 8,
                    runSpacing: 0,
                    children: [
                      _tagChip("{{nombre}}", "Nombre"),
                      _tagChip("{{id}}", "Documento"),
                      _tagChip("{{direcciones}}", "Sedes"),
                      _tagChip("{{fecha}}", "Fecha"),
                      _tagChip("{{firma}}", "Firma"),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                const Text("Cuerpo del Documento", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                const Divider(),

                TextField(
                  controller: _bodyController,
                  enabled: !widget.isReadOnly,
                  maxLines: null,
                  minLines: 12,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: "Escribe aquí...",
                    filled: true,
                    fillColor: widget.isReadOnly ? Colors.grey[50] : Colors.white,
                    border: widget.isReadOnly ? InputBorder.none : const OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 30),

                if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTemplate,
                      icon: const Icon(Icons.cloud_done, color: Colors.white),
                      label: const Text("GUARDAR", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                    ),
                  ),
                
                if (widget.isReadOnly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 10),
                        Text("Modo lectura: No se permiten cambios.",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _tagChip(String tag, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _insertHotkey(tag),
      backgroundColor: Colors.indigo.withOpacity(0.08),
      labelStyle: const TextStyle(color: Colors.indigo, fontSize: 11, fontWeight: FontWeight.bold),
      side: const BorderSide(color: Colors.indigo, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}