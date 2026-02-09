import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para escuchar cambios en el estado del usuario (Login/Logout)
  Stream<User?> get userStream => _auth.authStateChanges();

  // --- REGISTRO CON ROL ---
  Future<void> signUp(String email, String password, String role) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Guardamos el perfil del usuario con su rol en Firestore
      await _db.collection('users').doc(res.user!.uid).set({
        'email': email,
        'role': role, // 'admin' o 'worker'
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Enviamos correo de verificación por seguridad
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
  // Vital para saber a qué Dashboard redirigir
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