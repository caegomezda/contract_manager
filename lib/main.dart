import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de Pantallas
import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart';
import 'package:contract_manager/ui/screens/splash_screen.dart';
import 'package:contract_manager/ui/screens/legal/disclaimer_screen.dart';
import 'package:contract_manager/ui/screens/auth/login_screen.dart';
import 'package:contract_manager/ui/screens/auth/signup_screen.dart';
import 'package:contract_manager/ui/screens/auth/verify_email_screen.dart';
import 'package:contract_manager/ui/screens/auth/reset_password_screen.dart';

// Configuración de Firebase
import 'firebase_options.dart';

/// Punto de entrada principal de la aplicación.
/// Inicializa los servicios de Firebase y configura la persistencia de datos local.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuración de optimización para Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

/// Widget principal que define el tema de la aplicación y el sistema de rutas.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contract Manager',
      // La Splash Screen gestiona la lógica inicial de navegación
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

/// Componente de seguridad legal que intercepta el acceso a los Dashboards.
/// Verifica en las preferencias locales si el usuario ha aceptado los términos.
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

  /// Consulta SharedPreferences para determinar si debe mostrar el Disclaimer.
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return _needsLegal ? const LegalDisclaimerScreen() : widget.child;
  }
}

/// Gestiona el estado de la sesión y el enrutamiento basado en roles.
/// Escucha cambios en la autenticación y redirige al Dashboard correspondiente o al Login.
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

        final user = snapshot.data;

        // Caso: No autenticado
        if (user == null) return const LoginScreen();

        // Caso: Email no verificado
        if (!user.emailVerified) return const VerifyEmailScreen();

        // Caso: Autenticado, verificamos rol en Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
              final String role = roleSnapshot.data!['role'] ?? 'user';
              
              final Widget targetDashboard = role == 'admin' 
                  ? const AdminDashboard() 
                  : const UserDashboard();
              
              // Protegemos el dashboard con la verificación legal
              return LegalCheckWrapper(child: targetDashboard);
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}