import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- GESTIÓN DE CLIENTES ---

  /// Crea o actualiza un cliente con foto (Base64) y firma
  Future<void> saveClient({
    String? id,
    required String name,
    required String clientId,
    required String contractType,
    required List<String> addresses,
    required String signatureBase64,
    File? photoFile,
    required bool termsAccepted,
  }) async {
    String? photoBase64;

    // 1. Si hay una foto nueva, la procesamos a String Base64
    if (photoFile != null) {
      photoBase64 = await _processPhotoToBase64(photoFile);
    }

    // 2. Preparamos el mapa de datos
    final Map<String, dynamic> clientData = {
      'name': name,
      'client_id': clientId,
      'contract_type': contractType,
      'addresses': addresses,
      'signature_path': signatureBase64, // Firma en Base64
      'terms_accepted': termsAccepted,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Guardamos la foto como texto dentro del documento de Firestore
    if (photoBase64 != null) {
      clientData['photo_data_base64'] = photoBase64;
    }

    // 3. Guardamos en Firestore
    if (id == null) {
      // Es un cliente nuevo
      await _db.collection('clients').doc(clientId).set(clientData);
    } else {
      // Es una actualización/renovación
      await _db.collection('clients').doc(id).update(clientData);
    }
  }

  /// Convierte el archivo de imagen a una cadena Base64
  /// Nota: Asegúrate de que en la UI el ImagePicker use 'imageQuality' bajo
  Future<String?> _processPhotoToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Verificación de seguridad: Firestore limita el documento a 1MB total
      if (bytes.lengthInBytes > 1000000) {
        // ignore: avoid_print
        print("Advertencia: La imagen es demasiado grande para Firestore.");
      }
      return base64Encode(bytes);
    } catch (e) {
      // ignore: avoid_print
      print("Error procesando imagen a Base64: $e");
      return null;
    }
  }

  /// Escuchar la lista de clientes en tiempo real
/// Escuchar la lista de clientes con soporte para metadatos offline
  Stream<List<Map<String, dynamic>>> getClientsStream() {
    // includeMetadataChanges: true permite que la UI se actualice 
    // cuando el estado cambia de "local" a "sincronizado"
    return _db.collection('clients')
        .orderBy('updated_at', descending: true)
        .snapshots(includeMetadataChanges: true) 
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; 
              // Agregamos esta bandera para usarla en la UI
              data['is_local'] = doc.metadata.hasPendingWrites; 
              return data;
            }).toList());
  }
  // --- GESTIÓN DE PLANTILLAS (ADMIN) ---

  Future<void> saveContractTemplate(String title, String body) async {
    final docId = title.toLowerCase().replaceAll(' ', '_');
    await _db.collection('templates').doc(docId).set({
      'title': title,
      'body': body,
      'last_edit': FieldValue.serverTimestamp(),
    });
  }

/// Obtener todas las plantillas disponibles para el Administrador
  Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _db.collection('templates')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<DocumentSnapshot> getTemplate(String templateId) {
    return _db.collection('templates').doc(templateId).get();
  }
}

