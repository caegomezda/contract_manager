import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contract_manager/main.dart';

class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aviso Legal")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.gavel_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "IMPORTANTE: Herramienta de Gestión Contable",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "Esta aplicación es una herramienta tecnológica diseñada para facilitar la recolección de datos y la organización administrativa. \n\n"
                  "1. No constituye asesoría legal profesional.\n"
                  "2. Los modelos de contrato son sugerencias y deben ser revisados por un abogado.\n"
                  "3. El desarrollador no se hace responsable por el uso indebido de la información o incumplimientos contractuales entre las partes.\n"
                  "4. Usted acepta que el uso de esta app es bajo su propia responsabilidad bajo un entorno de gestión contable interna.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Guardar que ya vio el aviso
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('seen_legal', true);

                  // SOLUCIÓN 3: Validar montado antes de usar el context (async gap)
                  if (!context.mounted) return;

                  // Reiniciar flujo hacia el AuthWrapper
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("ENTIENDO Y ACEPTO"),
              ),
            )
          ],
        ),
      ),
    );
  }
}