import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante para la sesión
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/auth/verify_email_screen.dart';
import 'ui/screens/auth/reset_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CONFIGURACIÓN MODO OFFLINE ---
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Quitamos initialRoute porque 'home' manejará la lógica inicial
      home: const AuthWrapper(), 
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify': (context) => const VerifyEmailScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/user_dashboard': (context) => const UserDashboard(),
      },
    );
  }
}

// --- ESTE ES EL FILTRO DE SESIÓN ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Si está cargando la sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Si hay un usuario logueado
        if (snapshot.hasData) {
          User user = snapshot.data!;
          
          // Verificamos si el email está validado
          if (!user.emailVerified) {
            return const VerifyEmailScreen();
          }

          // Verificamos el rol en Firestore para saber a qué Dashboard ir
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                String role = roleSnapshot.data!['role'] ?? 'user';
                return role == 'admin' ? const AdminDashboard() : const UserDashboard();
              }

              // Si algo falla al obtener el rol, por seguridad mandamos a Login
              return const LoginScreen();
            },
          );
        }

        // 3. Si no hay nadie logueado
        return const LoginScreen();
      },
    );
  }
}