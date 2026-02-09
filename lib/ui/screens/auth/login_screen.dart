// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'verify_email_screen.dart'; // Asegúrate de que este archivo exista

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Ingresa tus credenciales completas");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Autenticación básica
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) throw "Error al obtener usuario";

      // 2. Verificación de Email (Opcional pero recomendado)
      if (!user.emailVerified) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
        );
        return;
      }

      // 3. Verificación de Perfil y Rol en Firestore
      // Nota: Usamos la colección 'users' que definimos en AuthService
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Verificamos si la cuenta está activa (campo 'status' según tu AuthService)
        if (userData['status'] == 'inactive') {
          await FirebaseAuth.instance.signOut();
          throw "Tu cuenta está inactiva. Contacta al soporte.";
        }

        String role = userData['role'] ?? 'worker';
        
        if (!mounted) return;

        // Redirección basada en el rol definido en el UserModel
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user_dashboard');
        }
      } else {
        // Si el usuario existe en Auth pero no en Firestore, lo cerramos por seguridad
        await FirebaseAuth.instance.signOut();
        throw "No se encontró un perfil de usuario configurado.";
      }
    } on FirebaseAuthException catch (e) {
      String message = "Error de acceso";
      if (e.code == 'user-not-found') message = "Correo no registrado";
      if (e.code == 'wrong-password') message = "Contraseña incorrecta";
      if (e.code == 'invalid-credential') message = "Credenciales inválidas";
      if (e.code == 'user-disabled') message = "Usuario inhabilitado";
      _showError(message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.redAccent, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo - Usando el estilo visual de tu captura
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.08),
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.description_rounded, size: 70, color: Colors.indigo),
                ),
                const SizedBox(height: 15),
                const Text(
                  "ContractFlow", 
                  style: TextStyle(
                    fontSize: 34, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.indigo, 
                    letterSpacing: -0.5
                  )
                ),
                const Text(
                  "Gestión Eficiente de Contratos", 
                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 30),
                
                _buildInput(
                  "Correo Electrónico", 
                  Icons.email_outlined, 
                  controller: _emailController, 
                  type: TextInputType.emailAddress
                ),
                const SizedBox(height: 18),
                _buildInput(
                  "Contraseña", 
                  Icons.lock_outline_rounded, 
                  controller: _passwordController, 
                  isPass: true,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                ),
                
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/reset'), 
                    child: const Text(
                      "¿Olvidaste tu contraseña?", 
                      style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600, fontSize: 13)
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        )
                      : const Text(
                          "INICIAR SESIÓN", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)
                        ),
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes cuenta?", 
                      style: TextStyle(color: Colors.blueGrey)
                    ),
                    TextButton(
                      // Usamos un padding mínimo para que no empuje el texto innecesariamente
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/signup'), 
                      child: const Text(
                        "Regístrate aquí", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.indigo
                        )
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, {
    required TextEditingController controller, 
    bool isPass = false, 
    Widget? suffix, 
    TextInputType type = TextInputType.text
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPass ? _obscurePassword : false,
          keyboardType: type,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(icon, color: Colors.indigo, size: 22),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF8F9FE),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEDF0F7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}