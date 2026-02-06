import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- GESTIÓN DE CLIENTES ---

  /// Crea o actualiza un cliente con foto y firma
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
    String? photoUrl;

    // 1. Si hay una foto nueva, la subimos a Firebase Storage
    if (photoFile != null) {
      photoUrl = await _uploadPhoto(clientId, photoFile);
    }

    // 2. Preparamos el mapa de datos
    final Map<String, dynamic> clientData = {
      'name': name,
      'client_id': clientId,
      'contract_type': contractType,
      'addresses': addresses,
      'signature_path': signatureBase64, // Guardamos el base64 para el PDF rápido
      'terms_accepted': termsAccepted,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (photoUrl != null) {
      clientData['photo_url'] = photoUrl;
    }

    // 3. Guardamos en Firestore
    if (id == null) {
      // Es un cliente nuevo: el documento tendrá el ID del cliente (cédula/NIT)
      await _db.collection('clients').doc(clientId).set(clientData);
    } else {
      // Es una actualización/renovación
      await _db.collection('clients').doc(id).update(clientData);
    }
  }

  /// Sube la foto del local a Storage y retorna la URL
  Future<String> _uploadPhoto(String clientId, File file) async {
    try {
      final ref = _storage.ref().child('client_photos/$clientId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print("Error subiendo foto: $e");
      return "";
    }
  }

  /// Escuchar la lista de clientes en tiempo real
  Stream<List<Map<String, dynamic>>> getClientsStream() {
    return _db.collection('clients')
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Incluimos el ID de Firestore
              return data;
            }).toList());
  }

  // --- GESTIÓN DE PLANTILLAS (ADMIN) ---

  /// Guarda la plantilla del contrato creada por el Admin
  Future<void> saveContractTemplate(String title, String body) async {
    final docId = title.toLowerCase().replaceAll(' ', '_');
    await _db.collection('templates').doc(docId).set({
      'title': title,
      'body': body,
      'last_edit': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene una plantilla específica
  Future<DocumentSnapshot> getTemplate(String templateId) {
    return _db.collection('templates').doc(templateId).get();
  }
}