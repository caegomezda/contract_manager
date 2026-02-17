// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:contract_manager/config/app_config.dart'; // Importamos tu configuración
import 'package:contract_manager/ui/screens/admin/admin_contract_dashboard.dart';
import 'package:contract_manager/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'worker_clients_screen.dart';
import 'package:flutter/services.dart';

class AdminDashboard extends StatelessWidget {
  final DatabaseService _db = DatabaseService();

  AdminDashboard({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                "EQUIPO DE TRABAJO",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.getUsersStream(currentUid, 'admin'),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final workers = snapshot.data!;
              if (workers.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("No hay trabajadores a tu cargo",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _workerCard(context, workers[i]),
                    childCount: workers.length,
                  ),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // --- LÓGICA DE USUARIOS Y CORRECCIÓN DE OVERFLOW ---
  void _showAddUserBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'worker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Invitar",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 5),
              const Text("Se generará un código de acceso para el nuevo integrante.",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 25),

              _buildInputLabel("Nombre Completo"),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(Icons.person_outline, "Ej: Juan Pérez"),
              ),
              const SizedBox(height: 20),

              _buildInputLabel("Correo Electrónico"),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(Icons.email_outlined, "correo@ejemplo.com"),
              ),
              const SizedBox(height: 20),

              _buildInputLabel("Rol de Usuario"),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedRole,
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text("Trabajador")),
                  DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
                  DropdownMenuItem(value: 'admin', child: Text("Administrador")),
                ],
                onChanged: (val) => selectedRole = val!,
                decoration: _inputDecoration(Icons.badge_outlined, ""),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (nameController.text.isEmpty || emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Rellena todos los campos")));
                        return;
                      }

                      final String code = await _db.adminCreateUser(
                          email: emailController.text.trim(),
                          name: nameController.text.trim(),
                          role: selectedRole);

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (code != "ERROR") {
                          _showSuccessDialog(context, nameController.text.trim(), code);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al crear la invitación")));
                        }
                      }
                    },
                    child: const Text("CREAR",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String name, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              const SizedBox(height: 15),
              Text("¡Invitación Lista!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo[900])),
              const SizedBox(height: 8),
              Text("Para: $name", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 25),
              const Text("Toca el código para copiarlo:", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ Código $code copiado"), behavior: SnackBarBehavior.floating),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(code, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 5, color: Colors.indigo)),
                        ),
                        const Icon(Icons.copy_all_rounded, color: Colors.indigo),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("ENTENDIDO"),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS UI ---

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
    );
  }

  Widget _workerCard(BuildContext context, Map<String, dynamic> worker) {

    final String uid = worker['uid'] ?? '';
    final String role = (worker['role'] ?? 'worker').toString().toLowerCase();
    
    // Intenta obtener el código de invitación de varios posibles nombres de campo
    final String? accessCode = worker['auth_code']?.toString();
    
    final bool isSuperAdmin = (worker['role'] == 'super_admin') || kSuperAdminUids.contains(uid);
    final bool isExpired = _checkIfExpired(worker['auth_valid_until']);
    final String expiryText = _formatDate(worker['auth_valid_until']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isSuperAdmin ? Colors.amber[50] : (isExpired ? Colors.red[50] : Colors.indigo[50]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
              isSuperAdmin
                  ? Icons.stars_rounded
                  : (role == 'supervisor' ? Icons.visibility_rounded : Icons.person),
              color: isSuperAdmin ? Colors.amber[800] : (isExpired ? Colors.red : Colors.indigo)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(worker['name'] ?? 'Usuario',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(role.toUpperCase(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("Vence: $expiryText",
                style: TextStyle(
                    fontSize: 11,
                    color: isExpired ? Colors.red : Colors.green[700],
                    fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) => _handleMenuAction(context, val, worker),
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'view', 
                child: ListTile(
                  leading: Icon(Icons.folder_copy_outlined, color: Colors.indigo), 
                  title: Text("Contratos", style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )),
            if (accessCode != null && accessCode.toString().isNotEmpty)
              PopupMenuItem(
                value: 'copy_code', 
                child: ListTile(
                  leading: const Icon(Icons.content_copy_rounded, color: Colors.blue), 
                  title: Text("Copiar Código: $accessCode", style: const TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )),
            const PopupMenuItem(
                value: 'renew', 
                child: ListTile(
                  leading: Icon(Icons.key_outlined, color: Colors.orange), 
                  title: Text("Renovar Acceso", style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )),
          ],
        ),
      ),
    );
  }
    
  bool _checkIfExpired(dynamic dateStr) {
    if (dateStr == null) return true;
    final expiry = DateTime.tryParse(dateStr.toString());
    return expiry == null || DateTime.now().isAfter(expiry);
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "SIN ACCESO";
    final date = DateTime.tryParse(dateStr.toString());
    return date != null ? DateFormat('dd/MM/yy').format(date) : "ERROR";
  }

  void _handleMenuAction(BuildContext context, String action, Map<String, dynamic> user) {
    if (action == 'view') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WorkerClientsScreen(
                    workerName: user['name'] ?? 'Desconocido',
                    workerId: user['uid'],
                  )));
    }else if (action == 'copy_code') {
        // Usamos 'auth_code' que es como vimos que se llama en tu consola
        final String code = (user['auth_code'] ?? '').toString();
        
        if (code.isNotEmpty) {
          // Intentamos la copia al portapapeles
          Clipboard.setData(ClipboardData(text: code)).then((_) {
            // Solo mostramos el SnackBar si la copia fue exitosa
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpia snackbars anteriores
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(child: Text("Código $code copiado para ${user['name']}")),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.indigo[900],
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          });
        } else {
          // Si por alguna razón el código está vacío en ese momento
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay un código activo para copiar")),
          );
        }
      }else if (action == 'renew') {
       _showRenewDialog(context, user);
      }
  }

  void _showRenewDialog(BuildContext context, Map<String, dynamic> user) {
    int selectedDays = 30;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Extender Acceso",
            style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Selecciona el nuevo periodo para ${user['name']}."),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: selectedDays,
              items: const [
                DropdownMenuItem(value: 7, child: Text("1 Semana")),
                DropdownMenuItem(value: 30, child: Text("1 Mes")),
                DropdownMenuItem(value: 365, child: Text("1 Año")),
              ],
              onChanged: (val) => selectedDays = val!,
              decoration: _inputDecoration(Icons.calendar_today_outlined, ""),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                await _db.renewUserAccess(user['uid'], selectedDays);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acceso actualizado")));
              },
              child: const Text("ACTUALIZAR")),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.indigo[800],
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
          onPressed: () => _handleLogout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[900]!, Colors.indigo[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _topMenuButton(
                      context,
                      Icons.description_rounded,
                      "Plantillas",
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const AdminContractDashboard()))),
                  const SizedBox(width: 20),
                  _topMenuButton(context, Icons.person_add_alt_1_rounded, "Invitar",
                      () => _showAddUserBottomSheet(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topMenuButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SliverToBoxAdapter(
      child: Center(child: Text("Error: $error", style: const TextStyle(color: Colors.red))),
    );
  }
}