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
  bool _isLoading = false;
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty || name.isEmpty) {
      _showError("Por favor, completa todos los campos");
      return;
    }

    if (pass.length < 6) {
      _showError("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // 2. Enviar Email de Verificación
      await userCredential.user!.sendEmailVerification();

      // 3. Crear perfil en Firestore (Rol 'worker' por defecto para operarios)
      // Nota: He cambiado 'user' a 'worker' para que coincida con la lógica de tu AdminDashboard
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'worker', 
        'active': true,
        'clients': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      // 4. Navegar a pantalla de verificación
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
            const SizedBox(height: 20),
            const Text("Crear Cuenta", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Text("Regístrate para comenzar a gestionar contratos", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 40),
            
            _input("Nombre completo", Icons.person_outline, _nameController),
            const SizedBox(height: 20),
            _input("Correo electrónico", Icons.email_outlined, _emailController, type: TextInputType.emailAddress),
            const SizedBox(height: 20),
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
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, 
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CREAR CUENTA", 
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
        labelStyle: const TextStyle(color: Colors.blueGrey),
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