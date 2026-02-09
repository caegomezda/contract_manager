// ignore_for_file: use_build_context_synchronously
import 'package:contract_manager/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Aviso Legal", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel_rounded, size: 60, color: Colors.amber),
              ),
              const SizedBox(height: 25),
              const Text(
                "TÉRMINOS DE USO Y RESPONSABILIDAD",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo),
              ),
              const SizedBox(height: 10),
              const Text(
                "Herramienta de Gestión Contractual",
                style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _disclaimerItem(
                        Icons.info_outline,
                        "Esta aplicación es una herramienta tecnológica diseñada para facilitar la recolección de datos y la organización administrativa interna.",
                      ),
                      _disclaimerItem(
                        Icons.gavel_outlined,
                        "No constituye asesoría legal profesional. Los modelos de contrato cargados son sugerencias y deben ser revisados por un profesional jurídico.",
                      ),
                      _disclaimerItem(
                        Icons.security_outlined,
                        "El desarrollador no se hace responsable por el uso indebido de la información, pérdida de datos o incumplimientos contractuales entre las partes.",
                      ),
                      _disclaimerItem(
                        Icons.verified_user_outlined,
                        "Usted acepta que el uso de esta app es bajo su propia responsabilidad en un entorno de gestión contable.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () async {
                    // Guardar persistencia
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('seen_legal', true);

                    if (!context.mounted) return;

                    // Navegar al AuthWrapper (o flujo principal)
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: const Text(
                    "ACEPTO LOS TÉRMINOS",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _disclaimerItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}