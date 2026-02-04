import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _selectedRole = 'user';

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
            const Text("Regístrate para comenzar a gestionar", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _input("Nombre completo", Icons.person_outline),
            const SizedBox(height: 15),
            _input("Correo electrónico", Icons.email_outlined),
            const SizedBox(height: 15),
            _input("Contraseña", Icons.lock_outline, isPass: true),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: "Tipo de Usuario",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'user', child: Text("Operador / Usuario")),
                DropdownMenuItem(value: 'admin', child: Text("Administrador")),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/verify'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("REGISTRARME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, IconData icon, {bool isPass = false}) {
    return TextField(
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}