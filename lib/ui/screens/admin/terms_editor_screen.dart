import 'package:flutter/material.dart';

/// Pantalla informativa sobre los términos legales.
/// Se accede desde el formulario de registro de cliente.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Información Legal", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.gavel_rounded, size: 50, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        "TÉRMINOS DE PRESTACIÓN DE SERVICIO",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    
                    _sectionTitle("1. Objeto del Servicio"),
                    _bodyText("El presente documento detalla la prestación de servicios técnicos y administrativos solicitados por el cliente. La aplicación actúa como un registro digital de la voluntad de las partes y soporte de la gestión realizada."),
                    
                    _sectionTitle("2. Veracidad de los Datos"),
                    _bodyText("El cliente declara que la información suministrada (identificación, dirección y contacto) es veraz. Cualquier error u omisión en los datos proporcionados es responsabilidad exclusiva del firmante."),
                    
                    _sectionTitle("3. Registro Fotográfico y Evidencia"),
                    _bodyText("Como medida de seguridad, transparencia y evidencia del estado del servicio, se capturarán fotografías del local, fachada o activos. Estas imágenes son para uso exclusivo de respaldo contractual y auditoría."),
                    
                    _sectionTitle("4. Validez de la Firma Digital"),
                    _bodyText("La firma estampada en la pantalla electrónica tiene plena validez legal como aceptación de las cláusulas aquí descritas, conforme a la normativa vigente de comercio electrónico y firmas digitales."),
                    
                    _sectionTitle("5. Exoneración de Responsabilidad"),
                    _bodyText("ContractFlow es una herramienta de gestión. El desarrollador no interviene en la relación comercial ni se hace responsable por incumplimientos contractuales entre el prestador y el cliente."),
                    
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        "Al marcar la casilla de aceptación en el formulario anterior, usted confirma que ha leído y aceptado estos términos.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Botón de cierre con diseño Indigo
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                ]
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("HE LEÍDO Y ENTIENDO", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(), 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo, letterSpacing: 0.8)
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6),
    );
  }
}