// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- GESTIÓN DE CLIENTES (FIRMAS Y CONTRATOS) ---

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
    final User? currentUser = _auth.currentUser;
    String? photoBase64;

    // 1. Procesamiento de imagen a Base64
    if (photoFile != null) {
      photoBase64 = await _processPhotoToBase64(photoFile);
    }

    // 2. Estructura de datos del cliente
    final Map<String, dynamic> clientData = {
      'name': name,
      'client_id': clientId,
      'contract_type': contractType,
      'addresses': addresses,
      'signature_path': signatureBase64, // Tu firma en Base64
      'terms_accepted': termsAccepted,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (photoBase64 != null) {
      clientData['photo_data_base64'] = photoBase64;
    }

    // --- LÓGICA DE GUARDADO INSTANTÁNEO ---
    try {
      final String docId = (id != null && id.isNotEmpty) ? id : clientId;
      DocumentReference clientRef = _db.collection('clients').doc(docId);

      if (id == null || id.isEmpty) {
        // ES UN NUEVO REGISTRO
        clientData['worker_id'] = manualWorkerId ?? currentUser?.uid;
        clientData['worker_name'] = manualWorkerName ?? (currentUser?.displayName ?? 'Operario');
        clientData['created_at'] = FieldValue.serverTimestamp();

        // QUITAMOS EL 'await': Firestore guarda localmente y sigue
        clientRef.set(clientData).catchError((e) => print("Error en background: $e"));

        // Actualizamos contador también sin esperar
        _updateTemplateCounter(contractType);

      } else {
        // ACTUALIZACIÓN: También sin 'await' para no bloquear la UI
        clientRef.update(clientData).catchError((e) => print("Error en background: $e"));
      }
      
      // Retornamos de inmediato para que la UI se desbloquee
      return; 

    } catch (e) {
      debugPrint("Error inmediato: $e");
      rethrow;
    }
  }

  /// Actualiza el contador de la plantilla de manera que funcione offline.
  /// Firestore permite usar FieldValue.increment() incluso sin conexión.
  void _updateTemplateCounter(String contractType) async {
    try {
      // Intentamos localizar la plantilla por su título. 
      // Nota: Para que sea 100% efectivo offline, el ID del doc en 'templates' 
      // debería ser el mismo título o tenerlo pre-identificado.
      final templateQuery = await _db.collection('templates')
          .where('title', isEqualTo: contractType)
          .get(const GetOptions(source: Source.serverAndCache));

      if (templateQuery.docs.isNotEmpty) {
        await templateQuery.docs.first.reference.update({
          'client_count': FieldValue.increment(1)
        });
      }
    } catch (e) {
      print("Error actualizando contador (no crítico): $e");
    }
  }

  Future<String?> _processPhotoToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  // --- STREAM DE CLIENTES CON SOPORTE OFFLINE ---
  Stream<List<Map<String, dynamic>>> getClientsStream() {
    String? uid = _auth.currentUser?.uid;
    return _db.collection('clients')
        .where('worker_id', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true) // IMPORTANTE para ver cambios locales
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; 
              return data;
            }).toList();
          
          // Ordenamos manualmente porque el orderBy de Firestore a veces falla offline 
          // si el índice no está creado o el timestamp es null (pendiente de subir)
          docs.sort((a, b) {
            final aTime = (a['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  // --- GESTIÓN DE PLANTILLAS (ADMIN) ---

  Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _db.collection('templates')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          
          docs.sort((a, b) {
            final aTime = (a['updated_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['updated_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); 
          });
          
          return docs;
        });
  }

  Future<void> saveTemplate({String? id, required String title, required String body}) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'body': body,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (id == null || id.isEmpty) {
        data['client_count'] = 0; 
        await _db.collection('templates').add(data);
      } else {
        await _db.collection('templates').doc(id).update(data);
      }
    } catch (e) {
      print("Error en saveTemplate: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTemplateByTitle(String title) async {
    final query = await _db.collection('templates')
        .where('title', isEqualTo: title)
        .get(const GetOptions(source: Source.serverAndCache));
    return query.docs.isNotEmpty ? query.docs.first.data() : null;
  }
}