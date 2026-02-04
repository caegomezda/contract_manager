import 'dart:convert';
// import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateFinalContract(Map<String, dynamic> client, String templateBody) async {
    final pdf = pw.Document();

    // EXPLICACIÓN: Aquí ocurre la magia de las Hotkeys
    // Tomamos el cuerpo del contrato y reemplazamos cada etiqueta por el dato real
    String processedText = templateBody
        .replaceAll('{{nombre}}', client['name'] ?? 'N/A')
        .replaceAll('{{id}}', client['client_id'] ?? 'N/A')
        .replaceAll('{{fecha}}', client['date'] ?? DateTime.now().toString().split(' ')[0])
        .replaceAll('{{direcciones}}', (client['addresses'] as List?)?.join(', ') ?? 'Sin direcciones');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("CONTRATO DE SERVICIO", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(processedText), // Insertamos el texto ya procesado
              pw.SizedBox(height: 40),
              if (client['signature_path'] != null && client['signature_path'].isNotEmpty)
                pw.Column(
                  children: [
                    pw.Text("FIRMA DEL CLIENTE:"),
                    pw.SizedBox(height: 10),
                    pw.Image(
                      pw.MemoryImage(base64Decode(client['signature_path'])),
                      height: 100,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}