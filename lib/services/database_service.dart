// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // --- GESTIÓN DE CLIENTES ---

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
    }

    // 2. Preparación del mapa de datos
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

    // --- LÓGICA DE VINCULACIÓN DE TRABAJADOR ---
    if (id == null || id.isEmpty) {
      // CASO NUEVO: Si no hay ID de documento, asignamos dueño
      clientData['worker_id'] = manualWorkerId ?? currentUser?.uid;
      clientData['worker_name'] = manualWorkerName ?? (currentUser?.displayName ?? 'Sin Nombre');
      
      await _db.collection('clients').doc(clientId).set(clientData);
    } else {
      // CASO ACTUALIZACIÓN: Solo sobreescribimos worker_id si se pasa explícitamente
      // Esto evita que el Admin se convierta en el dueño al editar.
      if (manualWorkerId != null) {
        clientData['worker_id'] = manualWorkerId;
        clientData['worker_name'] = manualWorkerName;
      }
      
      await _db.collection('clients').doc(id).update(clientData);
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

  Stream<List<Map<String, dynamic>>> getClientsStream() {
    String? uid = _auth.currentUser?.uid;
    return _db.collection('clients')
        .where('worker_id', isEqualTo: uid)
        .orderBy('updated_at', descending: true)
        .snapshots(includeMetadataChanges: true) 
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; 
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

  Future<Map<String, dynamic>?> getTemplateByTitle(String title) async {
    try {
      final query = await _db
          .collection('templates')
          .where('title', isEqualTo: title)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint("Error buscando plantilla: $e");
      return null;
    }
  }

  Future<void> saveTemplate({String? id, required String title, required String body}) async {
    try {
      // El mapa de datos que vamos a enviar
      final Map<String, dynamic> data = {
        'title': title,
        'body': body,
        'lastUpdate': FieldValue.serverTimestamp(),
        'client_count': id == null ? 0 : null,
      };

      if (id == null || id.isEmpty) {
        // Si es nueva plantilla, usamos .add()
        await _db.collection('templates').add(data);
      } else {
        // Si ya tiene ID, usamos .doc(id).set() o .update()
        await _db.collection('templates').doc(id).set(data, SetOptions(merge: true));
      }
      print("Guardado exitoso en Firebase");
    } catch (e) {
      print("Error detallado en DatabaseService: $e");
      rethrow; // Para que el UI capture el error y lo muestre
    }
  }

}