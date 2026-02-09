import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Información Legal", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.gavel_rounded, size: 60, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "TÉRMINOS DE PRESTACIÓN DE SERVICIO",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 40),
                    
                    // --- AQUÍ ESTÁ EL TEXTO INFORMATIVO ---
                    _sectionTitle("1. Objeto del Servicio"),
                    _bodyText("El presente documento detalla la prestación de servicios técnicos y administrativos solicitados por el cliente. La aplicación actúa como un registro digital de la voluntad de las partes."),
                    
                    _sectionTitle("2. Veracidad de los Datos"),
                    _bodyText("El cliente declara que la información suministrada (identificación, dirección y contacto) es veraz. Cualquier error en los datos es responsabilidad del firmante."),
                    
                    _sectionTitle("3. Registro Fotográfico"),
                    _bodyText("Como medida de seguridad y evidencia del estado del servicio, se capturarán fotografías del local o fachada. Estas imágenes son para uso exclusivo de respaldo contractual."),
                    
                    _sectionTitle("4. Firma Digital"),
                    _bodyText("La firma estampada en la pantalla táctil tiene validez legal como aceptación de las cláusulas aquí descritas, conforme a las leyes de comercio electrónico y firma digital vigentes."),
                    
                    _sectionTitle("5. Exonera de Responsabilidad"),
                    _bodyText("Contract Manager es una herramienta de gestión contable. El desarrollador no interviene en la relación contractual ni se hace responsable por incumplimientos entre las partes."),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            
            // Botón de cierre
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("ENTIENDO Y CONTINUAR", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widgets auxiliares para no repetir código y mantener orden
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent)),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
    );
  }
}