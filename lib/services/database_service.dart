import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // --- GESTIÓN DE CLIENTES ---

  /// Crea o actualiza un cliente vinculándolo automáticamente al usuario actual
  Future<void> saveClient({
    String? id,
    String? manualWorkerName, 
    String? manualWorkerId,   
    required String name,
    required String clientId,
    required String contractType,
    required List<String> addresses,
    required String signatureBase64,
    File? photoFile,
    required bool termsAccepted,
  }) async {
    String? photoBase64;
    final User? currentUser = _auth.currentUser;

    // 1. Procesamiento de imagen a Base64 si existe
    if (photoFile != null) {
      photoBase64 = await _processPhotoToBase64(photoFile);
      // Opcional: eliminar archivo temporal local para ahorrar espacio
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
    }

    // 2. Preparación del mapa de datos con vinculación de usuario
    final Map<String, dynamic> clientData = {
      'name': name,
      'client_id': clientId,
      'contract_type': contractType,
      'addresses': addresses,
      'signature_path': signatureBase64,
      'terms_accepted': termsAccepted,
      'updated_at': FieldValue.serverTimestamp(),
      
      // VINCULACIÓN CRUCIAL:
      'worker_id': manualWorkerId ?? currentUser?.uid,
      'worker_name': manualWorkerName ?? (currentUser?.displayName ?? 'Sin Nombre'),
    };

    if (photoBase64 != null) {
      clientData['photo_data_base64'] = photoBase64;
    }

    // 3. Escritura en Firestore
    if (id == null || id.isEmpty) {
      // Nuevo cliente: Usamos el ID del cliente como nombre de documento
      await _db.collection('clients').doc(clientId).set(clientData);
    } else {
      // Actualización: Usamos el ID interno de Firestore
      await _db.collection('clients').doc(id).update(clientData);
    }
  }

  /// Convierte imagen a String para almacenamiento directo en documento (límite 1MB)
  Future<String?> _processPhotoToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      // ignore: avoid_print
      print("Error procesando imagen: $e");
      return null;
    }
  }

  /// Escucha en tiempo real los clientes del usuario actual
  Stream<List<Map<String, dynamic>>> getClientsStream() {
    String? uid = _auth.currentUser?.uid;
    
    return _db.collection('clients')
        .where('worker_id', isEqualTo: uid) // Filtro de pertenencia
        .orderBy('updated_at', descending: true) // Los más recientes primero
        .snapshots(includeMetadataChanges: true) 
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; 
              data['is_local'] = doc.metadata.hasPendingWrites; // Bandera para icono de sincronización
              return data;
            }).toList());
  }

  // --- GESTIÓN DE PLANTILLAS (ADMIN) ---

  /// Guarda plantillas de contratos legales
  Future<void> saveContractTemplate(String title, String body) async {
    final docId = title.toLowerCase().replaceAll(' ', '_');
    await _db.collection('templates').doc(docId).set({
      'title': title,
      'body': body,
      'last_edit': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene el Stream de todas las plantillas para el Administrador
  Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _db.collection('templates')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Obtiene una plantilla específica por ID
  Future<DocumentSnapshot> getTemplate(String templateId) {
    return _db.collection('templates').doc(templateId).get();
  }
}