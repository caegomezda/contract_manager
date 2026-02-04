// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // Inicializamos con datos existentes si vienen en initialData
    _titleController = TextEditingController(text: widget.initialData?['title'] ?? '');
    _bodyController = TextEditingController(text: widget.initialData?['body'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // Función para insertar hotkeys en la posición del cursor
  void _insertHotkey(String tag) {
    if (widget.isReadOnly) return; // Seguridad extra

    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    // Si el cursor no está posicionado, lo ponemos al final
    int start = selection.start != -1 ? selection.start : text.length;
    int end = selection.end != -1 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, tag);
    _bodyController.text = newText;
    
    // Reposicionar el cursor justo después del tag insertado
    _bodyController.selection = TextSelection.collapsed(offset: start + tag.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "Detalle del Contrato" : "Configurar Plantilla"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (widget.isReadOnly)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.lock, color: Colors.orange), // Icono de candado para indicar bloqueo
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CAMPO DE TÍTULO
            TextField(
              controller: _titleController,
              enabled: !widget.isReadOnly, // Bloqueado si es ReadOnly
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Nombre del Contrato",
                border: widget.isReadOnly ? InputBorder.none : const UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // SECCIÓN DE HOTKEYS (Solo visible si no es ReadOnly)
            if (!widget.isReadOnly) ...[
              const Text("Variables Dinámicas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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

            // CAMPO DE TEXTO DEL CUERPO
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _bodyController,
                  enabled: !widget.isReadOnly, // Bloqueado si es ReadOnly
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: "Escribe el contenido legal aquí...",
                    filled: widget.isReadOnly,
                    fillColor: widget.isReadOnly ? Colors.grey[50] : Colors.white,
                    border: widget.isReadOnly ? InputBorder.none : const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // BOTÓN DE ACCIÓN
            if (!widget.isReadOnly)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Aquí iría la lógica para guardar en Firebase o DB Local
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Plantilla guardada exitosamente")),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("GUARDAR PLANTILLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            
            if (widget.isReadOnly)
              const Center(
                child: Text("Este contrato no se puede modificar porque ya tiene clientes asociados.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
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
        backgroundColor: Colors.blueAccent.withOpacity(0.05),
        labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 12),
        side: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}