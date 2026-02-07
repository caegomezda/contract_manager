import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'verify_email_screen.dart'; // Asegúrate de importar tu pantalla de verificación

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tus credenciales")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Autenticación en Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // 2. ¿El correo está verificado?
      if (user != null && !user.emailVerified) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
        );
        return;
      }

      // 3. Si está verificado, buscamos el rol en Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? 'user';
        if (!mounted) return;

        // Redirección según rol
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user_dashboard');
        }
      } else {
        throw "No se encontró el perfil de usuario.";
      }
    } on FirebaseAuthException catch (e) {
      String error = "Error al ingresar. Revisa tus datos.";
      if (e.code == 'user-not-found') error = "Usuario no registrado.";
      if (e.code == 'wrong-password') error = "Contraseña incorrecta.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_rounded, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text("ContractFlow", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              _buildTextField("Correo Electrónico", Icons.email_outlined, controller: _emailController),
              const SizedBox(height: 15),
              _buildTextField("Contraseña", Icons.lock_outline, obscure: true, controller: _passwordController),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/reset'), 
                  child: const Text("¿Olvidaste tu contraseña?")
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("INGRESAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'), 
                child: const Text("¿No tienes cuenta? Regístrate aquí")
              ),
              const SizedBox(height: 20),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool obscure = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}