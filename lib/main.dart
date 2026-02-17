// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelos
import 'package:contract_manager/data/models/user_model.dart';

// Importaciones de Pantallas
import 'package:contract_manager/ui/screens/home/admin_dashboard.dart';
import 'package:contract_manager/ui/screens/home/user_dashboard.dart'; 
import 'package:contract_manager/ui/screens/legal/disclaimer_screen.dart';
import 'package:contract_manager/ui/screens/auth/login_screen.dart';
import 'package:contract_manager/ui/screens/auth/signup_screen.dart';
import 'package:contract_manager/ui/screens/auth/verify_email_screen.dart';
import 'package:contract_manager/ui/screens/auth/reset_password_screen.dart';
import 'package:contract_manager/ui/screens/auth/token_lock_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      title: 'Contract Manager',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthWrapper(), 
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify': (context) => const VerifyEmailScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/admin_dashboard': (context) => AdminDashboard(),
        '/user_dashboard': (context) => const UserDashboard(),
      },
    );
  }
}

// --- WRAPPER LEGAL ---
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
    if (mounted) setState(() { _needsLegal = !hasSeenLegal; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _needsLegal ? const LegalDisclaimerScreen() : widget.child;
  }
}

// --- AUTH WRAPPER CON GUARDIÁN DE ACCESO ACTUALIZADO ---
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

        // Verificación de Email
        if (!firebaseUser.emailVerified) return const VerifyEmailScreen();

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).snapshots(),
          builder: (context, userSnap) {
            // Manejo de estados de carga y error de Firestore
            if (userSnap.hasError) return const LoginScreen();

            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const LoginScreen(); 
            }

            final data = userSnap.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(data, userSnap.data!.id);

            // --- NUEVA LÓGICA DE PRIORIDAD Y BLOQUEO ---

            // Calculamos estados de expiración
            final bool isDateExpired = userModel.authValidUntil == null || 
                                       DateTime.now().isAfter(userModel.authValidUntil!);
            
            final bool needsValidation = data['is_validated'] == false;

            // 1. FILTRO DE SEGURIDAD PARA WORKERS Y SUPERVISORES
            // Si el rol es 'worker' o 'supervisor', verificamos si está bloqueado.
            if (userModel.role == 'worker' || userModel.role == 'supervisor') {
              if (isDateExpired || needsValidation) {
                return TokenLockScreen(user: userModel);
              }
            }

            // 2. REDIRECCIÓN A DASHBOARDS SEGÚN ROL
            // Solo llegan aquí si:
            // a) Son Admin/SuperAdmin (siempre pasan)
            // b) Son Worker/Supervisor con token VÁLIDO.
            
            if (userModel.isSuperAdmin || 
                userModel.role == 'super_admin' || 
                userModel.role == 'admin' || 
                userModel.role == 'supervisor') {
              return LegalCheckWrapper(child: AdminDashboard());
            }

            // Dashboard por defecto para trabajadores validados
            return LegalCheckWrapper(child: const UserDashboard());
          },
        );
      },
    );
  }
}