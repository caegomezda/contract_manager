import 'package:contract_manager/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PendingInvitationsPage extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();

  PendingInvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Fondo igual a tu pantalla principal
      appBar: AppBar(
        title: const Text("Invitaciones Pendientes", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _dbService.getPendingInvitationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No hay invitaciones pendientes", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final invitations = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final inv = invitations[index];
              final String email = inv['email'] ?? 'Sin email';
              final String code = inv['auth_code'] ?? '----';
              final String role = inv['role'] ?? 'worker';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: Nombre y Botón Borrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              inv['name'] ?? 'Usuario invitado',
                              style: const TextStyle(
                                fontSize: 17, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142)
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, email),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      // Badge de Rol y Sección de Código
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Badge del Rol
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5
                              ),
                            ),
                          ),
                          // Sección del Código (Clickable para copiar)
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Código $code copiado"),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD966)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFB7860B)),
                                  const SizedBox(width: 8),
                                  Text(
                                    code,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFB7860B),
                                      letterSpacing: 1.5
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función para confirmar antes de borrar
  void _confirmDelete(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar invitación"),
        content: Text("¿Estás seguro de que quieres eliminar la invitación para $email?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              _dbService.deleteInvitation(email);
              Navigator.pop(context);
            }, 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}