import 'package:flutter/material.dart';

class TermsEditorScreen extends StatelessWidget {
  const TermsEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
const String terminosLegales = """
TÉRMINOS Y CONDICIONES DE USO Y TRATAMIENTO DE DATOS

1. OBJETO
El presente documento regula el registro, captura de evidencia y firma digital de contratos de prestación de servicios gestionados a través de la plataforma de gestión de contratos.

2. TRATAMIENTO DE DATOS PERSONALES
El cliente autoriza de manera previa, expresa e informada a la Empresa y al personal técnico u operario identificado durante la visita, para recolectar, almacenar y procesar sus datos personales, incluyendo:
• Datos de identificación (Nombre completo y documento de identidad).
• Ubicación geográfica y direcciones de servicio.
• Registro fotográfico del establecimiento, activos o entorno.
• Firma biométrica y digital.

Estos datos serán utilizados exclusivamente para la validación del servicio, ejecución del contrato, auditoría técnica y cumplimiento de requisitos legales de seguridad.

3. VALIDEZ DE LA FIRMA DIGITAL
Las partes aceptan y reconocen que la firma capturada mediante el panel táctil de este dispositivo móvil cumple con los requisitos de integridad, fiabilidad y autenticidad necesarios para ser vinculante, teniendo la misma validez y efectos jurídicos que una firma autógrafa o manuscrita.

4. EVIDENCIA FOTOGRÁFICA
La captura de imágenes se realiza como soporte técnico obligatorio para validar la prestación efectiva del servicio, la presencia del técnico en el sitio y el estado de los activos o del local al momento de la firma o renovación del contrato.

5. ALMACENAMIENTO Y SEGURIDAD
Toda la información recolectada será cifrada y almacenada en servidores con altos estándares de seguridad. El titular de los datos podrá solicitar el acceso, rectificación o eliminación de su información a través de los canales de atención oficiales de la empresa.
""";
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo ligeramente gris para resaltar el "papel"
      appBar: AppBar(
        title: const Text("Documento Legal", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const Icon(Icons.gavel_rounded, size: 40, color: Colors.blueGrey),
                    const SizedBox(height: 20),
                    const Text(
                      "CONTRATO DE ACEPTACIÓN DIGITAL",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 15),
                    // Aquí usamos Text en lugar deFormField para que sea SOLO LECTURA
                    SelectableText(
                      terminosLegales,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                        fontFamily: 'serif', // Fuente con serifa para look legal
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón inferior
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "ENTENDIDO Y CERRAR",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}