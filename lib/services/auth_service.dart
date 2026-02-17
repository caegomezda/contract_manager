import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para escuchar cambios en el estado del usuario (Login/Logout)
  Stream<User?> get userStream => _auth.authStateChanges();

  // --- REGISTRO CON ROL (MODIFICADO PARA VINCULAR SUPERVISOR) ---
  Future<void> signUp(String email, String password, String role, String name) async {
    try {
      // 1. Buscamos si existe una invitación para este email para heredar datos
      DocumentSnapshot invDoc = await _db.collection('invitations').doc(email).get();
      
      String? supervisorId;
      String? parentAdminId;
      
      if (invDoc.exists) {
        final data = invDoc.data() as Map<String, dynamic>;
        supervisorId = data['supervisor_id']; // Aquí obtenemos quién lo invitó
        parentAdminId = data['parent_admin_id'];
      }

      // 2. Crear el usuario en Firebase Auth
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // 3. Guardamos el perfil con el vínculo del supervisor
      await _db.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid,
        'email': email,
        'name': name,
        'role': role, 
        'supervisor_id': supervisorId ?? '', // Si venía de invitación, se guarda el ID del supervisor
        'parent_admin_id': parentAdminId ?? '',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Borramos la invitación ya que el registro fue exitoso
      if (invDoc.exists) {
        await _db.collection('invitations').doc(email).delete();
      }

      // Enviamos correo de verificación
      await res.user!.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // --- INICIO DE SESIÓN ---
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // --- OBTENER ROL DEL USUARIO ---
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') ?? 'worker';
      }
      return 'worker';
    } catch (e) {
      return 'worker';
    }
  }

  // --- RECUPERAR CONTRASEÑA ---
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}