// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // --- GENERADOR DE BYTES (Con fix de fuentes Unicode) ---
  static Future<Uint8List> _generatePdfBytes(Map<String, dynamic> clientData, String termsBody) async {
    final pdf = pw.Document();

    // Usamos fuentes que soportan Unicode para evitar los errores de Helvetica
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    String processedBody = termsBody
        .replaceAll('{{nombre}}', clientData['name'] ?? 'N/A')
        .replaceAll('{{id}}', clientData['client_id'] ?? 'N/A')
        .replaceAll('{{contrato}}', clientData['contract_type'] ?? 'N/A')
        .replaceAll('{{fecha}}', DateTime.now().toString().split(' ')[0]);

    Uint8List? signatureBytes;
    if (clientData['signature_path'] != null && clientData['signature_path'].isNotEmpty) {
      try {
        signatureBytes = base64Decode(clientData['signature_path']);
      } catch (e) {
        debugPrint("Error firma: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        // Aplicamos el tema de fuentes para que no falle con tildes o ñ
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("CONTRATO DE PRESTACIÓN DE SERVICIOS",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 15),
                pw.Text("DATOS DEL CLIENTE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text("Nombre: ${clientData['name']}"),
                pw.Text("Identificación: ${clientData['client_id']}"),
                pw.Text("Tipo de Contrato: ${clientData['contract_type']}"),
                pw.SizedBox(height: 25),
                pw.Text("TÉRMINOS Y CONDICIONES", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text(processedBody, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.justify),
                pw.Spacer(), 
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [
                      if (signatureBytes != null) pw.Container(height: 80, width: 160, child: pw.Image(pw.MemoryImage(signatureBytes))),
                      pw.Container(width: 160, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())), child: pw.Text("Firma Cliente", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
                    ]),
                    pw.Column(children: [
                      pw.SizedBox(height: 80),
                      pw.Container(width: 160, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())), child: pw.Text("Sello Verificación", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
                    ]),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  // --- MÉTODO PARA DESCARGAR (USANDO CANAL NATIVO) ---
  static Future<void> downloadContract(BuildContext context, Map<String, dynamic> clientData, String termsBody) async {
    try {
      final bytes = await _generatePdfBytes(clientData, termsBody);
      final String fileName = 'Contrato_${clientData['name'].toString().replaceAll(' ', '_')}.pdf';

      // Esta función es la más robusta para Android moderno.
      // Abrirá un diálogo donde el usuario solo da clic en "Guardar en Descargas" o "Drive".
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Selecciona 'Guardar en dispositivo' para finalizar"),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error en descarga: $e");
    }
  }

  // --- MÉTODO PARA VISUALIZAR ---
  static Future<void> previewContract(BuildContext context, Map<String, dynamic> clientData, String termsBody) async {
    final bytes = await _generatePdfBytes(clientData, termsBody);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Vista Previa del Contrato"), backgroundColor: Colors.blueAccent),
          body: PdfPreview(
            build: (format) => bytes,
            allowPrinting: false, // Desactivamos para que no confunda con el otro botón
            allowSharing: false,  // Desactivamos para que use exclusivamente tu botón de descarga
            initialPageFormat: PdfPageFormat.letter,
            pdfFileName: 'Contrato_${clientData['name']}.pdf',
          ),
        ),
      ),
    );
  }
}