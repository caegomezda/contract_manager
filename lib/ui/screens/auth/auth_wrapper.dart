import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:contract_manager/data/models/user_model.dart';

import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart'; 
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
        // 1. Cargando estado de autenticación
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Si no hay usuario, vamos al Login
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        final firebaseUser = authSnapshot.data!;

        // 3. Verificamos email
        if (!firebaseUser.emailVerified) {
          return const VerifyEmailScreen();
        }

        // 4. USAMOS UN FUTUREBUILDER PARA FORZAR UNA PETICIÓN FRESCA A FIRESTORE
        // El source: Source.server obliga a ignorar el caché que te está dando problemas
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get(const GetOptions(source: Source.serverAndCache)), 
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnap.hasError || !userSnap.hasData || !userSnap.data!.exists) {
              // Si hay error de permisos al re-entrar, cerramos sesión para limpiar
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            final data = userSnap.data!.data() as Map<String, dynamic>;
            
            // --- LÓGICA DE ROLES SEGURA ---
            final String role = (data['role'] ?? 'worker').toString().toLowerCase();
            final bool isSuper = data['is_super_admin'] ?? false;

            debugPrint("AUTH_SUCCESS: Usuario ${firebaseUser.email} con Rol: $role");

            if (role == 'admin' || role == 'super_admin' || isSuper) {
              return const AdminDashboard();
            }

            // --- LÓGICA DE WORKER ---
            try {
              final userModel = UserModel.fromMap(data, userSnap.data!.id);
              final bool isExpired = userModel.authValidUntil == null || 
                                   DateTime.now().isAfter(userModel.authValidUntil!);

              if (isExpired) {
                return TokenLockScreen(user: userModel);
              }
              return const UserDashboard();
            } catch (e) {
              return const UserDashboard(); // Fallback
            }
          },
        );
      },
    );
  }
}