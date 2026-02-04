import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Agregamos controladores para capturar el texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // 2. Importante: Limpiar controladores al cerrar la pantalla
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              
              // 3. Pasamos los controladores a los campos
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
                  onPressed: () {
                    // Aquí llamarías a: AuthService().signIn(_emailController.text, _passwordController.text);
                    debugPrint("Intentando entrar con: ${_emailController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("INGRESAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              
              // 4. Botón para ir a Registro
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'), 
                child: const Text("¿No tienes cuenta? Regístrate aquí")
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const Text("Probar como:", style: TextStyle(color: Colors.grey)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(onPressed: () => _bypass(context, 'admin'), child: const Text("ADMIN")),
                  TextButton(onPressed: () => _bypass(context, 'user'), child: const Text("OPERADOR")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bypass(BuildContext context, String role) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => HomeScreen(mockRole: role))
    );
  }

  // 5. Ajustamos el helper para recibir el controlador
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