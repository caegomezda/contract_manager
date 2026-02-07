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

  Future<void> _registerUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, completa todos los campos")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Enviar Email de Verificación
      await userCredential.user!.sendEmailVerification();

      // 3. Crear perfil en Firestore (Rol user por defecto)
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user', 
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
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Crear Cuenta", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Regístrate para comenzar a trabajar", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _input("Nombre completo", Icons.person_outline, _nameController),
            const SizedBox(height: 15),
            _input("Correo electrónico", Icons.email_outlined, _emailController),
            const SizedBox(height: 15),
            _input("Contraseña", Icons.lock_outline, _passwordController, isPass: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("REGISTRARME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}