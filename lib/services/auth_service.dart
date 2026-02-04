import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream del estado de autenticación
  Stream<User?> get user => _auth.authStateChanges();

  // Registro con Rol
  Future<void> signUp(String email, String password, String role) async {
    // UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    // await _db.collection('users').doc(res.user!.uid).set({
    //   'email': email,
    //   'role': role,
    //   'status': 'active'
    // });
    // await res.user!.sendEmailVerification();
  }

  // Recuperar Contraseña
  Future<void> resetPassword(String email) async {
    // await _auth.sendPasswordResetEmail(email: email);
  }
}