// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // --- GENERADOR DE BYTES ---
  static Future<Uint8List> _generatePdfBytes(Map<String, dynamic> clientData, String termsBody) async {
    final pdf = pw.Document();

    // Cargamos fuentes locales
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final font = pw.Font.ttf(fontData);
    
    // Intentamos cargar Bold, si no está usamos la misma Regular para evitar errores de compilación
    pw.Font fontBold;
    try {
      final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      fontBold = pw.Font.ttf(fontBoldData);
    } catch (_) {
      fontBold = font;
    }

    // 1. LIMPIEZA PROFUNDA DE CARACTERES (Adiós a las "X")
    // Eliminamos \r (retorno de carro) y caracteres de control invisibles que causan los cuadros
    String cleanBody = termsBody
        .replaceAll('\r', '') // Elimina el causante principal en Windows
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ''); // Limpia otros caracteres de control

    String processedBody = cleanBody
        .replaceAll('{{nombre}}', clientData['name'] ?? 'N/A')
        .replaceAll('{{id}}', clientData['client_id'] ?? 'N/A')
        .replaceAll('{{contrato}}', clientData['contract_type'] ?? 'N/A')
        .replaceAll('{{direcciones}}', clientData['address'] ?? 'N/A')
        .replaceAll('{{monto}}', clientData['monto'] ?? '0.00') 
        .replaceAll('{{fecha}}', DateTime.now().toString().split(' ')[0]);

    // 2. DECODIFICAR FIRMA
    Uint8List? signatureBytes;
    if (clientData['signature_path'] != null && clientData['signature_path'].toString().isNotEmpty) {
      try {
        String base64String = clientData['signature_path'].toString();
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        signatureBytes = base64Decode(base64String);
      } catch (e) {
        debugPrint("Error decodificando firma: $e");
      }
    }

    pdf.addPage(
      pw.MultiPage( 
        pageFormat: PdfPageFormat.letter,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("CONTRACTFLOW SYSTEM", 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo, fontSize: 12)),
                pw.Text("ID DOC: ${DateTime.now().millisecondsSinceEpoch}", 
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ],
            ),
            pw.Divider(color: PdfColors.indigo),
            pw.SizedBox(height: 15),

            // Cuadro de Datos
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("INFORMACIÓN DEL TITULAR", 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.indigo)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(child: _buildInfoField("Nombre", clientData['name'] ?? 'N/A')),
                      pw.Expanded(child: _buildInfoField("Identificación", clientData['client_id'] ?? 'N/A')),
                    ]
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      pw.Expanded(child: _buildInfoField("Servicio", clientData['contract_type'] ?? 'N/A')),
                      pw.Expanded(child: _buildInfoField("Monto", clientData['monto'] ?? 'N/A')),
                    ]
                  ),
                  pw.SizedBox(height: 5),
                  _buildInfoField("Sedes/Dirección", clientData['address'] ?? 'No especificada'),
                ],
              ),
            ),

            pw.SizedBox(height: 25),
            
            // Cuerpo del Contrato (Usamos Paragraph para evitar desbordamientos)
            pw.Text("TÉRMINOS, CLÁUSULAS Y CONDICIONES", 
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 10),
            pw.Paragraph(
              text: processedBody, 
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 3), 
              textAlign: pw.TextAlign.justify
            ),
            
            pw.SizedBox(height: 40),

            // Área de Firmas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    if (signatureBytes != null) 
                      pw.Image(pw.MemoryImage(signatureBytes), height: 60, width: 120)
                    else
                      pw.SizedBox(height: 60),
                    pw.Container(
                      width: 180, 
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey700)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Column(
                        children: [
                          pw.Text(clientData['name'].toString().toUpperCase(), 
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text("FIRMA DEL CLIENTE", style: const pw.TextStyle(fontSize: 7)),
                        ]
                      )
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      height: 60,
                      alignment: pw.Alignment.center,
                      child: pw.Text("VERIFICADO", 
                        style: pw.TextStyle(color: PdfColors.grey400, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Container(
                      width: 180, 
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey700)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Column(
                        children: [
                          pw.Text("CONTRACTFLOW SYSTEM", 
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text("AUTORIZACIÓN DIGITAL", style: const pw.TextStyle(fontSize: 7)),
                        ]
                      )
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text("Documento generado electrónicamente. No requiere firma física para su validez legal.",
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            )
          ];
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildInfoField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: "$label: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 8)),
          ]
        )
      )
    );
  }

  static Future<void> downloadContract(BuildContext context, Map<String, dynamic> clientData, String termsBody) async {
    try {
      final bytes = await _generatePdfBytes(clientData, termsBody);
      final String fileName = 'Contrato_${clientData['name'].toString().replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  static Future<void> previewContract(BuildContext context, Map<String, dynamic> clientData, String termsBody) async {
    try {
      final bytes = await _generatePdfBytes(clientData, termsBody);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text("Vista Previa"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            body: PdfPreview(
              build: (format) => bytes,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              initialPageFormat: PdfPageFormat.letter,
              pdfFileName: 'Contrato_${clientData['name']}.pdf',
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}