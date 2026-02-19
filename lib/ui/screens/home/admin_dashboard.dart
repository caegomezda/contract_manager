// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/main.dart';
import 'package:contract_manager/ui/screens/admin/admin_contract_dashboard.dart';
import 'package:contract_manager/services/database_service.dart';
import 'package:contract_manager/ui/screens/home/pending_invitations_page.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'worker_clients_screen.dart';
import 'package:flutter/services.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = "";
  String _selectedFilter = "Todos"; 

  String currentUserRole = '';
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => currentUserId = user.uid);
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          setState(() {
            currentUserRole = (doc.data()?['role'] ?? 'worker').toString().toLowerCase();
          });
        }
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          _buildSearchAndFilters(),
          _buildSectionHeader(context),
          _buildUserList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.indigo[800],
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () => _handleLogout(context),
        )
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo[900]!, Colors.indigo[600]!],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _topMenuButton(
                      context, 
                      Icons.description_rounded, 
                      "Plantillas",
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminContractDashboard())),
                    ),
                  ),
                  Expanded(
                    child: _topMenuButton(
                      context, 
                      Icons.group_work_rounded, 
                      "Clientes",
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserDashboard())),
                    ),
                  ),
                  // REGLA: Todos pueden ver el botón de invitar, la restricción está dentro del formulario
                  Expanded(
                    child: _topMenuButton(
                      context, 
                      Icons.person_add_alt_1_rounded, 
                      "Invitar",
                      () => _showAddUserBottomSheet(context),
                    ),
                  ),
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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: _inputDecoration(Icons.search, "Buscar por nombre o correo...").copyWith(
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    }) 
                  : null
              ),
            ),
            // Solo Super Admin y Admin ven filtros de rol
            if (currentUserRole != 'supervisor') ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["Todos", "Admin", "Supervisor", "Worker"].map((filter) {
                    bool isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter == "Worker" ? "Trabajadores" : filter),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedFilter = filter),
                        selectedColor: Colors.indigo[100],
                        checkmarkColor: Colors.indigo,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey[300]!)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("USUARIOS", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, fontSize: 13, letterSpacing: 1.5)),
            if (currentUserRole == 'admin' || currentUserRole == 'super_admin')
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PendingInvitationsPage())),
                label: const Text("INVITACIONES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                icon: const Icon(Icons.mail_outline, size: 16),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUsersStream(currentUserId, currentUserRole),
      builder: (context, snapshot) {
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}")));
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final users = snapshot.data!.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          final role = (u['role'] ?? '').toString().toLowerCase();
          final supervisorId = (u['supervisor_id'] ?? '').toString();
          
          bool matchesSearch = name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
          bool matchesFilter = _selectedFilter == "Todos" || role == _selectedFilter.toLowerCase();
          
          // REGLA DE VISIBILIDAD DE HISTORIAL
          bool matchesHierarchy = true;
          if (currentUserRole == 'supervisor') {
            matchesHierarchy = (role == 'worker' && supervisorId == currentUserId);
          } else if (currentUserRole == 'admin') {
            matchesHierarchy = (role != 'super_admin' && role != 'admin');
          }

          return matchesSearch && matchesFilter && matchesHierarchy;
        }).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, i) => _workerCard(context, users[i]), childCount: users.length),
          ),
        );
      },
    );
  }

  // --- CARD DE USUARIO ---

  Widget _workerCard(BuildContext context, Map<String, dynamic> worker) {
    final String role = (worker['role'] ?? 'worker').toString().toLowerCase();
    final String? accessCode = worker['auth_code']?.toString();
    final bool isPrivileged = role == 'admin' || role == 'super_admin';
    final bool isValidated = worker['is_validated'] ?? false;
    final dynamic rawExpiry = worker['auth_valid_until'];
    
    DateTime? expiryDate;
    if (rawExpiry is Timestamp) expiryDate = rawExpiry.toDate();
    else if (rawExpiry is String) expiryDate = DateTime.tryParse(rawExpiry);

    final bool isExpired = !isPrivileged && (!isValidated || (expiryDate != null && DateTime.now().isAfter(expiryDate)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: isExpired ? Colors.red[50] : Colors.indigo[50], borderRadius: BorderRadius.circular(15)),
          child: Icon(isPrivileged ? Icons.admin_panel_settings : (role == 'supervisor' ? Icons.visibility_rounded : Icons.person), color: isExpired ? Colors.red : Colors.indigo),
        ),
        title: Text(worker['name'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
            if (!isPrivileged)
              Text("Vence: ${_formatDate(worker['auth_valid_until'])}", style: TextStyle(fontSize: 11, color: isExpired ? Colors.red : Colors.green[700], fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) => _handleMenuAction(context, val, worker),
          itemBuilder: (context) {
            bool canManage = currentUserRole != 'supervisor';
            return [
              const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.folder_copy_outlined, color: Colors.indigo), title: Text("Clientes", style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
              if (canManage) ...[
                const PopupMenuItem(value: 'change_role', child: ListTile(leading: Icon(Icons.manage_accounts_outlined, color: Colors.deepPurple), title: Text("Cambiar Rol", style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
                if (!isPrivileged && accessCode != null)
                  PopupMenuItem(value: 'copy_code', child: ListTile(leading: const Icon(Icons.content_copy_rounded, color: Colors.blue), title: const Text("Copiar Código", style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
                if (!isPrivileged)
                  const PopupMenuItem(value: 'renew', child: ListTile(leading: Icon(Icons.key_outlined, color: Colors.orange), title: Text("Renovar Acceso", style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
              ]
            ];
          },
        ),
      ),
    );
  }

  // --- DIÁLOGOS Y FORMULARIOS ---

  void _showAddUserBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    
    // Lógica de rol inicial según quién invita
    String selectedRole = 'worker';
    if (currentUserRole == 'admin') selectedRole = 'supervisor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("Nueva Invitación", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 25),
            _buildInputLabel("Nombre Completo"),
            TextField(controller: nameController, decoration: _inputDecoration(Icons.person_outline, "Ej: Juan Pérez")),
            const SizedBox(height: 20),
            _buildInputLabel("Correo Electrónico"),
            TextField(controller: emailController, decoration: _inputDecoration(Icons.email_outlined, "correo@ejemplo.com")),
            const SizedBox(height: 20),
            _buildInputLabel("Rol"),
            DropdownButtonFormField<String>(
              value: selectedRole,
              // FILTRO DE ROLES SEGÚN HISTORIAL:
              items: _getAvailableRolesForInvitation(), 
              onChanged: (val) => selectedRole = val!,
              decoration: _inputDecoration(Icons.badge_outlined, ""),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty) return;
                final code = await _db.adminCreateUser(email: emailController.text.trim(), name: nameController.text.trim(), role: selectedRole);
                Navigator.pop(context);
                if (code != "ERROR") _showSuccessDialog(context, nameController.text.trim(), code);
              },
              child: const Text("ENVIAR INVITACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para filtrar roles en el Dropdown de invitación
  List<DropdownMenuItem<String>> _getAvailableRolesForInvitation() {
    if (currentUserRole == 'supervisor') {
      return [const DropdownMenuItem(value: 'worker', child: Text("Trabajador"))];
    } else if (currentUserRole == 'admin') {
      return [const DropdownMenuItem(value: 'supervisor', child: Text("Supervisor"))];
    } else {
      return [
        const DropdownMenuItem(value: 'worker', child: Text("Trabajador")),
        const DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
        const DropdownMenuItem(value: 'admin', child: Text("Administrador")),
      ];
    }
  }

  void _showSuccessDialog(BuildContext context, String name, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("¡Invitación para $name!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Código de acceso:", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), 
              child: Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.indigo))
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR"))],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, Map<String, dynamic> user) {
    String role = user['role'] ?? 'worker';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Rol"),
        content: DropdownButtonFormField<String>(
          value: role,
          items: const [
            DropdownMenuItem(value: 'worker', child: Text("Trabajador")), 
            DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")), 
            DropdownMenuItem(value: 'admin', child: Text("Administrador"))
          ],
          onChanged: (val) => role = val!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('users').doc(user['uid']).update({'role': role});
            Navigator.pop(context);
          }, child: const Text("GUARDAR")),
        ],
      ),
    );
  }

  void _showRenewDialog(BuildContext context, Map<String, dynamic> user) {
    int days = 30;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renovar Acceso"),
        content: StatefulBuilder(
          builder: (context, setInternalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Días de acceso extra:"),
              DropdownButton<int>(
                value: days,
                isExpanded: true,
                items: [7, 15, 30, 60, 90].map((d) => DropdownMenuItem(value: d, child: Text("$d días"))).toList(),
                onChanged: (val) => setInternalState(() => days = val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(onPressed: () async {
            await _db.renewUserAccess(user['uid'], days);
            Navigator.pop(context);
          }, child: const Text("RENOVAR")),
        ],
      ),
    );
  }

  // --- HELPERS ---

  String _formatDate(dynamic dateData) {
    if (dateData == null) return "SIN FECHA";
    if (dateData is Timestamp) return DateFormat('dd/MM/yy').format(dateData.toDate());
    return dateData.toString();
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.indigo)),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)));
  }

  void _handleMenuAction(BuildContext context, String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        Navigator.push(context, MaterialPageRoute(builder: (context) => WorkerClientsScreen(workerName: user['name'] ?? '', workerId: user['uid'])));
        break;
      case 'change_role':
        _showChangeRoleDialog(context, user);
        break;
      case 'copy_code':
        Clipboard.setData(ClipboardData(text: user['auth_code'] ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código copiado al portapapeles")));
        break;
      case 'renew':
        _showRenewDialog(context, user);
        break;
    }
  }
}