// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _invitationCodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final pass = _passwordController.text.trim();
    final code = _invitationCodeController.text.trim();

    if (email.isEmpty || pass.isEmpty || name.isEmpty || code.isEmpty) {
      _showError("Por favor, completa todos los campos incluyendo el código");
      return;
    }

    if (pass.length < 6) {
      _showError("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. VALIDAR CÓDIGO EN LA COLECCIÓN DE INVITACIONES (LA SALA DE ESPERA)
      // Cambiamos 'users' por 'invitations'
      final inviteQuery = await FirebaseFirestore.instance
          .collection('invitations') 
          .where('email', isEqualTo: email)
          .where('auth_code', isEqualTo: code)
          .limit(1)
          .get();

      if (inviteQuery.docs.isEmpty) {
        _showError("Código de invitación inválido o correo no autorizado");
        setState(() => _isLoading = false);
        return;
      }

      // Extraer datos de la invitación (rol, admin que lo invitó, etc.)
      final invitationDoc = inviteQuery.docs.first;
      final invitationData = invitationDoc.data();

      // 2. CREAR USUARIO EN FIREBASE AUTH
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // 3. ENVIAR EMAIL DE VERIFICACIÓN
      await userCredential.user!.sendEmailVerification();

      // 4. CREAR PERFIL DEFINITIVO EN LA COLECCIÓN 'users'
      // Ahora sí, el usuario ya tiene UID de Auth y puede entrar a 'users'
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': invitationData['role'],
        'parent_admin_id': invitationData['parent_admin_id'],
        'supervisor_id': invitationData['supervisor_id'],
        'active': true, // Ahora ya es un usuario activo
        'is_super_admin': false,
        'clients': 0,
        'auth_valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 5. LIMPIAR LA INVITACIÓN (Para que el código no se use dos veces)
      await FirebaseFirestore.instance.collection('invitations').doc(email).delete();

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const VerifyEmailScreen())
      );
      
    } on FirebaseAuthException catch (e) {
      String message = "Ocurrió un error";
      if (e.code == 'weak-password') message = "La contraseña es muy débil";
      if (e.code == 'email-already-in-use') message = "Este correo ya está registrado";
      if (e.code == 'invalid-email') message = "El formato del correo es inválido";
      _showError(message);
    } catch (e) {
      _showError("Error inesperado: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- EL RESTO DEL CÓDIGO (UI) SE MANTIENE IGUAL ---

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Activar Cuenta", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Text("Ingresa el código que te proporcionó tu administrador", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 30),
            
            _input("Nombre completo", Icons.person_outline, _nameController),
            const SizedBox(height: 15),
            _input("Correo electrónico", Icons.email_outlined, _emailController, type: TextInputType.emailAddress),
            const SizedBox(height: 15),
            
            _input(
              "Código de Invitación (4 dígitos)", 
              Icons.vpn_key_outlined, 
              _invitationCodeController,
              type: TextInputType.number
            ),
            
            const SizedBox(height: 15),
            _input(
              "Contraseña", 
              Icons.lock_outline, 
              _passwordController, 
              isPass: true,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity, 
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("REGISTRAR", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("¿Ya tienes cuenta? Inicia sesión", 
                  style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, IconData icon, TextEditingController controller, 
      {bool isPass = false, Widget? suffix, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPass ? _obscurePassword : false,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
      ),
    );
  }
}