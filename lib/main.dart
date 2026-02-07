import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart';
import 'package:contract_manager/ui/screens/splash_screen.dart'; // Importa tu nueva Splash
import 'package:contract_manager/ui/screens/legal/disclaimer_screen.dart'; // Importa el Disclaimer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Necesario para el disclaimer
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/auth/verify_email_screen.dart';
import 'ui/screens/auth/reset_password_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      // 1. El punto de entrada ahora es la Splash Screen
      home: const CustomSplashScreen(), 
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

// --- WRAPPER PARA VERIFICAR LEGAL ANTES DE ENTRAR ---
class LegalCheckWrapper extends StatefulWidget {
  final Widget child;
  const LegalCheckWrapper({super.key, required this.child});

  @override
  State<LegalCheckWrapper> createState() => _LegalCheckWrapperState();
}

class _LegalCheckWrapperState extends State<LegalCheckWrapper> {
  bool _isLoading = true;
  bool _needsLegal = true;

  @override
  void initState() {
    super.initState();
    _checkLegalStatus();
  }

  Future<void> _checkLegalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenLegal = prefs.getBool('seen_legal') ?? false;
    if (mounted) {
      setState(() {
        _needsLegal = !hasSeenLegal;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Si no ha visto el legal, mostramos la pantalla legal
    if (_needsLegal) return const LegalDisclaimerScreen();

    // Si ya lo vio, mostramos el dashboard que correspondía
    return widget.child;
  }
}

// --- FILTRO DE SESIÓN ACTUALIZADO ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          User user = snapshot.data!;
          
          if (!user.emailVerified) {
            return const VerifyEmailScreen();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                String role = roleSnapshot.data!['role'] ?? 'user';
                
                // 2. Envolvemos los Dashboards con el LegalCheckWrapper
                Widget targetDashboard = role == 'admin' 
                    ? const AdminDashboard() 
                    : const UserDashboard();
                
                return LegalCheckWrapper(child: targetDashboard);
              }

              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}