import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Asegúrate de tener firebase_core en pubspec
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/auth/verify_email_screen.dart';
import 'ui/screens/auth/reset_password_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Importar esto
import 'firebase_options.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CONFIGURACIÓN MODO OFFLINE ---
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Habilita el guardado en disco local
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // O un límite (ej. 100 * 1024 * 1024 para 100MB)
  );

  runApp(const MyApp());
  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify': (context) => const VerifyEmailScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(), // <--- ¿Se llama así?
        '/user_dashboard': (context) => const UserDashboard(),
      },
    );
  }
}