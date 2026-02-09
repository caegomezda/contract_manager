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
      'signature_path': signatureBase64,
      'terms_accepted': termsAccepted,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (photoBase64 != null) {
      clientData['photo_data_base64'] = photoBase64;
    }

    // --- LÓGICA DE VINCULACIÓN Y TRANSACCIÓN ---
    try {
      await _db.runTransaction((transaction) async {
        // Referencia al documento del cliente
        DocumentReference clientRef = _db.collection('clients').doc(id ?? clientId);
        
        // Referencia a la plantilla para aumentar el contador de usos
        QuerySnapshot templateQuery = await _db.collection('templates')
            .where('title', isEqualTo: contractType)
            .limit(1)
            .get();

        if (id == null || id.isEmpty) {
          // Si es nuevo cliente, asignamos el trabajador
          clientData['worker_id'] = manualWorkerId ?? currentUser?.uid;
          clientData['worker_name'] = manualWorkerName ?? (currentUser?.displayName ?? 'Operario');
          transaction.set(clientRef, clientData);

          // Si encontramos la plantilla, aumentamos su contador de firmas
          if (templateQuery.docs.isNotEmpty) {
            transaction.update(templateQuery.docs.first.reference, {
              'client_count': FieldValue.increment(1)
            });
          }
        } else {
          // Si es actualización
          transaction.update(clientRef, clientData);
        }
      });
    } catch (e) {
      debugPrint("Error en transacción de guardado: $e");
      rethrow;
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

  // Stream para que el operario vea sus últimos clientes registrados
  Stream<List<Map<String, dynamic>>> getClientsStream() {
    String? uid = _auth.currentUser?.uid;
    return _db.collection('clients')
        .where('worker_id', isEqualTo: uid)
        .orderBy('updated_at', descending: true)
        .limit(20) 
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; 
              return data;
            }).toList());
  }

  // --- GESTIÓN DE PLANTILLAS (ADMIN) ---

  Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _db.collection('templates')
        // Quitamos el orderBy temporalmente para verificar si es el error del índice
        // O lo dejamos pero aseguramos que el documento exista
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          
          // Ordenamos manualmente en memoria para evitar errores de índice en Firebase
          docs.sort((a, b) {
            final aTime = (a['updated_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['updated_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); // Descendente
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
        data['client_count'] = 0; // Inicializamos contador
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
        .limit(1)
        .get();
    return query.docs.isNotEmpty ? query.docs.first.data() : null;
  }
}