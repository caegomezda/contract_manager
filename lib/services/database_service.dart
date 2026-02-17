// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'dart:math'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

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

    if (photoFile != null) {
      photoBase64 = await _processPhotoToBase64(photoFile);
    }

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

    try {
      final String docId = (id != null && id.isNotEmpty) ? id : clientId;
      DocumentReference clientRef = _db.collection('clients').doc(docId);

      if (id == null || id.isEmpty) {
        clientData['worker_id'] = manualWorkerId ?? currentUser?.uid;
        clientData['worker_name'] = manualWorkerName ?? (currentUser?.displayName ?? 'Operario');
        clientData['created_at'] = FieldValue.serverTimestamp();

        clientRef.set(clientData).catchError((e) => print("Error en background: $e"));
        _updateTemplateCounter(contractType);

      } else {
        clientRef.update(clientData).catchError((e) => print("Error en background: $e"));
      }
      
      return; 

    } catch (e) {
      debugPrint("Error inmediato: $e");
      rethrow;
    }
  }

  void _updateTemplateCounter(String contractType) async {
    try {
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

  Stream<List<Map<String, dynamic>>> getClientsStream() {
    String? uid = _auth.currentUser?.uid;
    return _db.collection('clients')
        .where('worker_id', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; 
              return data;
            }).toList();
          
          docs.sort((a, b) {
            final aTime = (a['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  // --- GESTIÓN DE USUARIOS, ROLES E INVITACIONES ---

  Future<String> adminCreateUser({
    required String email,
    required String name,
    required String role, 
    String? supervisorId,
  }) async {
    try {
      final String currentUid = _auth.currentUser?.uid ?? '';
      final String initialAuthCode = (Random().nextInt(8999) + 1000).toString();
      final DateTime initialExpiry = DateTime.now().add(const Duration(hours: 48)); 
      final String cleanEmail = email.toLowerCase().trim();

      await _db.collection('invitations').doc(cleanEmail).set({
        'email': cleanEmail,
        'name': name,
        'role': role,
        'parent_admin_id': currentUid, 
        'supervisor_id': currentUid,
        'auth_code': initialAuthCode,
        'auth_valid_until': initialExpiry.toIso8601String(),
        'is_validated': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      return initialAuthCode;
    } catch (e) {
      print("Error en adminCreateUser: $e");
      return "ERROR";
    }
  }

  // --- NUEVA CONFIGURACIÓN: RECUPERACIÓN DE INVITACIONES ---
  Stream<List<Map<String, dynamic>>> getPendingInvitationsStream() {
    return _db.collection('invitations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<Map<String, dynamic>?> validateInvitation(String email, String code) async {
    try {
      final doc = await _db.collection('invitations').doc(email.toLowerCase().trim()).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['auth_code'] == code) {
          final expiry = DateTime.parse(data['auth_valid_until']);
          if (DateTime.now().isBefore(expiry)) {
            return data;
          }
        }
      }
      return null;
    } catch (e) {
      print("Error validando invitación: $e");
      return null;
    }
  }

  Future<void> deleteInvitation(String email) async {
    await _db.collection('invitations').doc(email.toLowerCase().trim()).delete();
  }

  Stream<List<Map<String, dynamic>>> getUsersStream(String currentUid, String role) {
    if (role == 'admin') {
      final streamColegas = _db.collection('users')
          .where('role', whereIn: ['admin', 'supervisor'])
          .snapshots();

      final streamTodosLosWorkers = _db.collection('users')
          .where('role', isEqualTo: 'worker')
          .snapshots();

      final streamYo = _db.collection('users').doc(currentUid).snapshots();

      return Rx.combineLatest3(
        streamColegas, 
        streamTodosLosWorkers, 
        streamYo, 
        (QuerySnapshot colegas, QuerySnapshot workers, DocumentSnapshot yo) {
          final Map<String, Map<String, dynamic>> result = {};

          for (var doc in colegas.docs) {
            result[doc.id] = doc.data() as Map<String, dynamic>..['uid'] = doc.id;
          }
          for (var doc in workers.docs) {
            result[doc.id] = doc.data() as Map<String, dynamic>..['uid'] = doc.id;
          }
          if (yo.exists) {
            result[yo.id] = (yo.data() as Map<String, dynamic>)..['uid'] = yo.id;
          }

          final finalList = result.values.toList();
          finalList.removeWhere((u) => u['role'] == 'super_admin');
          finalList.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
          return finalList;
        }
      );
    } 
    
    Query query = _db.collection('users');
    if (role == 'supervisor') {
      query = query.where('supervisor_id', isEqualTo: currentUid);
    } 

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
      return list;
    });
  }

  Future<void> demoteSupervisorToWorker({required String supervisorUid}) async {
    try {
      final supervisorQuery = await _db.collection('users')
          .where('role', isEqualTo: 'supervisor')
          .get();

      String? firstAvailableSupervisorId;

      for (var doc in supervisorQuery.docs) {
        if (doc.id != supervisorUid) {
          firstAvailableSupervisorId = doc.id;
          break; 
        }
      }

      final WriteBatch batch = _db.batch();
      final orphanWorkers = await _db.collection('users')
          .where('supervisor_id', isEqualTo: supervisorUid)
          .get();

      for (var doc in orphanWorkers.docs) {
        batch.update(doc.reference, {
          'supervisor_id': firstAvailableSupervisorId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      batch.update(_db.collection('users').doc(supervisorUid), {
        'role': 'worker',
        'supervisor_id': firstAvailableSupervisorId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print("Error en demoteSupervisorToWorker: $e");
      rethrow;
    }
  }

  Future<void> updateUserRole({
    required String targetUid, 
    required String newRole, 
    required bool isTargetSuperAdmin
  }) async {
    try {
      if (isTargetSuperAdmin) return;
      await _db.collection('users').doc(targetUid).update({
        'role': newRole,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error en updateUserRole: $e");
      rethrow;
    }
  }

  Future<void> renewUserAccess(String targetUid, int days) async {
    try {
      final String newCode = (Random().nextInt(8999) + 1000).toString();
      final DateTime expiryDate = DateTime.now().add(Duration(days: days));

      await _db.collection('users').doc(targetUid).update({
        'auth_code': newCode,
        'auth_valid_until': expiryDate.toIso8601String(),
        'is_validated': false, 
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error en renewUserAccess: $e");
    }
  }

  Future<void> assignWorkerToSupervisor(String workerUid, String supervisorUid) async {
    await _db.collection('users').doc(workerUid).update({
      'supervisor_id': supervisorUid,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // --- GESTIÓN DE PLANTILLAS ---

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