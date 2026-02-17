import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:contract_manager/data/models/user_model.dart';

// REVISIÓN DE RUTAS: Usamos las rutas que vimos en tu main.dart
import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart'; // UserDashboard es tu "WorkerHome"
import 'package:contract_manager/ui/screens/auth/login_screen.dart';
import 'package:contract_manager/ui/screens/auth/verify_email_screen.dart';
import 'package:contract_manager/ui/screens/auth/token_lock_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!authSnapshot.hasData) return const LoginScreen();

        final firebaseUser = authSnapshot.data!;

        // Si el email no está verificado
        if (!firebaseUser.emailVerified) return const VerifyEmailScreen();

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const LoginScreen(); 
            }

            final data = userSnap.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(data, userSnap.data!.id);

            // 1. Lógica para Admins (Super o Normal)
            if (userModel.isSuperAdmin || userModel.role == 'super_admin' || userModel.role == 'admin') {
              return AdminDashboard(); // Asegúrate de que la clase en ese archivo se llame así
            }

            // 2. Lógica para Workers con bloqueo de Token
            final bool isExpired = userModel.authValidUntil == null || 
                                   DateTime.now().isAfter(userModel.authValidUntil!);

            if (isExpired) {
              return TokenLockScreen(user: userModel);
            }

            // Si tiene acceso y es worker, va al dashboard de usuario
            return const UserDashboard();
          },
        );
      },
    );
  }
}