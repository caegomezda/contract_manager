// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:contract_manager/data/models/user_model.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TokenLockScreen extends StatefulWidget {
  final UserModel user;
  const TokenLockScreen({super.key, required this.user});

  @override
  State<TokenLockScreen> createState() => _TokenLockScreenState();
}

class _TokenLockScreenState extends State<TokenLockScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isError = false;
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final inputCode = _codeController.text.trim();
    
    if (inputCode == widget.user.authCode) {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      try {
        final DateTime newExpiryDate = DateTime.now().add(const Duration(days: 30));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
          'is_validated': true, 
          'auth_valid_until': Timestamp.fromDate(newExpiryDate),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // No es necesario navegar manualmente, el StreamBuilder del Main 
        // detectará 'is_validated: true' y refrescará la UI solo.
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión. Inténtalo de nuevo."))
        );
      }
    } else {
      setState(() {
        _isError = true;
        _isLoading = false;
        _codeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: PopScope(
        canPop: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[900]!, Colors.indigo[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          ),
          child: SafeArea(
            child: Center( // Centramos el contenido
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security_update_good_rounded, size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Renovación de Acceso",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 26, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Hola ${widget.user.name.split(' ')[0]},\nIngresa el código de seguridad para continuar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.indigo[100], fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 50),
                    
                    // SOLUCIÓN AL ERROR: El ConstrainedBox envuelve al TextField
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36, 
                          letterSpacing: 25, 
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo
                        ),
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: "0000",
                          hintStyle: TextStyle(color: Colors.indigo[100], letterSpacing: 20),
                          errorText: _isError ? "Código no válido" : null,
                          errorStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none
                          ),
                          counterText: "",
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Botón con ancho controlado
                    SizedBox(
                      width: 280,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Text(
                              "ACTIVAR ACCESO",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    TextButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                      label: const Text(
                        "Salir de la cuenta", 
                        style: TextStyle(color: Colors.white70, fontSize: 14)
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}