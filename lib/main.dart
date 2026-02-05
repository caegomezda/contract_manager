import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Asegúrate de tener firebase_core en pubspec
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/auth/verify_email_screen.dart';
import 'ui/screens/auth/reset_password_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Importar esto
import 'firebase_options.dart';

void main() async {
  // 3. Asegurar que los widgets estén listos antes de cargar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 4. Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      },
    );
  }
}