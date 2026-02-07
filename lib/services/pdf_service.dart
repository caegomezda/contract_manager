import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateFinalContract(
      Map<String, dynamic> clientData, String termsBody) async {
    final pdf = pw.Document();

    // 1. Inyectar variables dinámicas en el texto legal
    String processedBody = termsBody
        .replaceAll('{{nombre}}', clientData['name'] ?? 'N/A')
        .replaceAll('{{id}}', clientData['client_id'] ?? 'N/A')
        .replaceAll('{{contrato}}', clientData['contract_type'] ?? 'N/A')
        .replaceAll('{{fecha}}', DateTime.now().toString().split(' ')[0]);

    // 2. Decodificar la firma de Base64 a Bytes
    Uint8List? signatureBytes;
    if (clientData['signature_path'] != null && clientData['signature_path'].isNotEmpty) {
      signatureBytes = base64Decode(clientData['signature_path']);
    }

    // 3. Crear el diseño del PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Text("CONTRATO DE PRESTACIÓN DE SERVICIOS",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Datos del Cliente (Resumen)
              pw.Text("DATOS DEL CLIENTE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text("Nombre: ${clientData['name']}"),
              pw.Text("Identificación: ${clientData['client_id']}"),
              pw.Text("Tipo de Contrato: ${clientData['contract_type']}"),
              pw.SizedBox(height: 20),

              // Cuerpo de los Términos (Aquí va el texto de la plantilla ya procesado)
              pw.Text("TÉRMINOS Y CONDICIONES", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 5),
              pw.Text(processedBody, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.justify),
              
              pw.Spacer(), 

              // Sección de Firma
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (signatureBytes != null)
                        pw.Container(
                          height: 80,
                          width: 150,
                          child: pw.Image(pw.MemoryImage(signatureBytes)),
                        ),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)),
                        ),
                        child: pw.Text("Firma del Cliente", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 80),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)),
                        ),
                        child: pw.Text("Sello de Verificación", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // 4. Mostrar vista previa y permitir descarga/impresión
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Contrato_${clientData['name']}.pdf',
    );
  }
}