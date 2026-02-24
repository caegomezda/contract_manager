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
  bool _isLoadingRole = true; // NUEVO: Para controlar el parpadeo inicial

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          setState(() {
            currentUserRole = (doc.data()?['role'] ?? 'worker').toString().toLowerCase();
            _isLoadingRole = false; // Ya sabemos el rol, podemos mostrar la lista
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
    // Si aún no sabemos el rol, mostramos un indicador de carga centrado
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

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
    // Definimos qué opciones de filtro mostrar según el rol
    List<String> getFilterOptions() {
      if (currentUserRole == 'super_admin') {
        return ["Todos", "Admin", "Supervisor", "Worker"];
      } else if (currentUserRole == 'admin') {
        // El Admin solo puede filtrar por lo que puede ver: Supervisores y Workers
        return ["Todos", "Supervisor", "Worker"];
      } else {
        return ["Todos"]; // Por si acaso llegara un supervisor aquí
      }
    }

    final filterOptions = getFilterOptions();

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
            if (currentUserRole != 'supervisor') ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterOptions.map((filter) {
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), 
                          side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey[300]!)
                        ),
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

  Widget _workerCard(BuildContext context, Map<String, dynamic> worker) {
    final String role = (worker['role'] ?? 'worker').toString().toLowerCase();
    final String? accessCode = worker['auth_code']?.toString();
    final bool isPrivileged = role == 'admin' || role == 'super_admin';
    final bool isValidated = worker['is_validated'] ?? false;
    final dynamic rawExpiry = worker['auth_valid_until'];
    
    DateTime? expiryDate;
    if (rawExpiry is Timestamp) {
      expiryDate = rawExpiry.toDate();
    // ignore: curly_braces_in_flow_control_structures
    } else if (rawExpiry is String) expiryDate = DateTime.tryParse(rawExpiry);

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
          // Busca dentro del PopupMenuButton en _workerCard
          itemBuilder: (context) {
            bool canManage = currentUserRole != 'supervisor';
            return [
              const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.folder_copy_outlined, color: Colors.indigo), title: Text("Clientes", style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
              if (canManage) ...[
                const PopupMenuItem(value: 'change_role', child: ListTile(leading: Icon(Icons.manage_accounts_outlined, color: Colors.deepPurple), title: Text("Cambiar Rol", style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
                // ... otras opciones ...
              ],
              // NUEVA OPCIÓN DE ELIMINAR
              if (currentUserRole == 'super_admin')
                const PopupMenuItem(
                  value: 'delete', 
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red), 
                    title: Text("Eliminar Usuario", style: TextStyle(fontSize: 14, color: Colors.red)), 
                    contentPadding: EdgeInsets.zero, 
                    visualDensity: VisualDensity.compact
                  )
                ),
            ];
          },
        ),
      ),
    );
  }

  void _showAddUserBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    
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
    
    List<DropdownMenuItem<String>> getItems() {
      List<DropdownMenuItem<String>> menuItems = [];

      if (currentUserRole == 'super_admin') {
        menuItems = const [
          DropdownMenuItem(value: 'worker', child: Text("Trabajador")),
          DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
          DropdownMenuItem(value: 'admin', child: Text("Administrador")),
          DropdownMenuItem(value: 'super_admin', child: Text("Super Administrador")),
        ];
      } else {
        menuItems = const [
          DropdownMenuItem(value: 'worker', child: Text("Trabajador")),
          DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
        ];
      }

      bool roleExists = menuItems.any((item) => item.value == role);
      if (!roleExists) {
        return [
          ...menuItems,
          DropdownMenuItem(value: role, child: Text(role.toUpperCase())),
        ];
      }

      return menuItems;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cambiar Rol"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Selecciona el nuevo nivel de acceso:", softWrap: true),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: role,
                items: getItems(),
                onChanged: (val) => role = val!,
                decoration: _inputDecoration(Icons.badge_outlined, ""),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(user['uid']).update({'role': role});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Rol actualizado con éxito"))
              );
            }, 
            child: const Text("GUARDAR", style: TextStyle(color: Colors.white)),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        softWrap: true, 
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.blueGrey,
        ),
      ),
    );
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
      case 'delete':  
        _deleteUser(user);
        break;
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final String roleToDelete = user['role'] ?? 'worker';
    final String uidToDelete = user['uid'];

    // Solo el super_admin tiene este poder
    if (currentUserRole != 'super_admin') return;

    // Si es un trabajador, se puede borrar sin restricciones de conteo
    if (roleToDelete == 'worker') {
      _executeDeletion(uidToDelete, user['name']);
      return;
    }

    // Si es Admin o Supervisor, verificamos cuántos quedan en el sistema
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: roleToDelete)
          .get();

      if (querySnapshot.docs.length <= 1) {
        // Si hay 1 o menos, bloqueamos la acción
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No se puede eliminar al último ${roleToDelete.toUpperCase()} del sistema."),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        // Si hay más de uno, confirmamos con el usuario
        _confirmDeletion(user);
      }
    } catch (e) {
      debugPrint("Error al validar conteo: $e");
    }
  }

  void _confirmDeletion(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Estás seguro de que deseas eliminar a ${user['name']}? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _executeDeletion(user['uid'], user['name']);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeDeletion(String uid, String name) async {
    try {
      // Borramos el documento de Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Usuario eliminado de la base de datos"),
          content: Text("IMPORTANTE: Para que $name pueda volver a registrarse con el mismo correo, debes eliminar su cuenta manualmente desde la consola de Firebase Authentication (sección 'Users')."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("ENTENDIDO")
            )
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error eliminando: $e");
    }
  }
}