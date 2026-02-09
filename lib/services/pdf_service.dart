// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // --- GENERADOR DE BYTES ---
  static Future<Uint8List> _generatePdfBytes(Map<String, dynamic> clientData, String termsBody) async {
    final pdf = pw.Document();

    // Cargamos fuentes robustas para evitar errores de codificación
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Procesamos el cuerpo reemplazando las variables dinámicas
    String processedBody = termsBody
        .replaceAll('{{nombre}}', clientData['name'] ?? 'N/A')
        .replaceAll('{{id}}', clientData['client_id'] ?? 'N/A')
        .replaceAll('{{contrato}}', clientData['contract_type'] ?? 'N/A')
        .replaceAll('{{direcciones}}', clientData['address'] ?? 'N/A')
        .replaceAll('{{fecha}}', DateTime.now().toString().split(' ')[0]);

    // Decodificar firma desde Base64
    Uint8List? signatureBytes;
    if (clientData['signature_path'] != null && clientData['signature_path'].isNotEmpty) {
      try {
        signatureBytes = base64Decode(clientData['signature_path']);
      } catch (e) {
        debugPrint("Error decodificando firma: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado Profesional
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Documento Digital # ${DateTime.now().millisecondsSinceEpoch}", 
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                ],
              ),
              // Cuadro de Datos del Cliente
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("INFORMACIÓN DEL TITULAR", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Bullet(text: "Nombre: ${clientData['name']}"),
                    pw.Bullet(text: "Identificación: ${clientData['client_id']}"),
                    pw.Bullet(text: "Servicio: ${clientData['contract_type']}"),
                    pw.Bullet(text: "Dirección: ${clientData['address'] ?? 'No especificada'}"),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),
              
              // Cuerpo del Contrato
              pw.Text("CLÁUSULAS Y CONDICIONES", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Text(processedBody, 
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 2), 
                textAlign: pw.TextAlign.justify),
              
              pw.Spacer(), 

              // Área de Firmas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      if (signatureBytes != null) 
                        pw.Container(
                          height: 70, 
                          width: 140, 
                          child: pw.Image(pw.MemoryImage(signatureBytes))
                        ),
                      pw.Container(
                        width: 180, 
                        decoration: const pw.BoxDecoration( // Añade BoxDecoration aquí
                          border: pw.Border(top: pw.BorderSide(width: 1)),
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
                      pw.SizedBox(height: 70), // Espacio para sello físico si fuera necesario
                      pw.Container(
                        width: 180, 
                        decoration: pw.BoxDecoration( // El border SIEMPRE dentro de decoration
                          border: pw.Border.all(color: PdfColors.grey300, width: 1),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Column(
                          children: [
                            pw.Text("CONTRACTFLOW SYSTEM", 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text("SELLO DE VERIFICACIÓN DIGITAL", style: const pw.TextStyle(fontSize: 7)),
                          ]
                        )
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text("Este documento fue generado electrónicamente y es copia fiel de la voluntad del firmante.",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              )
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // --- MÉTODO PARA DESCARGAR / COMPARTIR ---
  static Future<void> downloadContract(BuildContext context, Map<String, dynamic> clientData, String termsBody) async {
    try {
      final bytes = await _generatePdfBytes(clientData, termsBody);
      final String fileName = 'Contrato_${clientData['name'].toString().replaceAll(' ', '_')}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Documento listo para guardar o enviar"),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
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
          appBar: AppBar(
            title: const Text("Vista Previa"), 
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat.letter,
            pdfFileName: 'Preview_${clientData['name']}.pdf',
          ),
        ),
      ),
    );
  }
}