import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/accountant/accountant_dashboard.dart';
import 'screens/secretary/secretary_dashboard.dart';
import 'screens/staff/staff_dashboard.dart';
import 'services/authentication_service.dart';
import 'services/update_service.dart';
import 'app_theme.dart';
import 'app_settings.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot_password';
  static const String adminDashboard = '/admin_dashboard';
  static const String teacherDashboard = '/teacher_dashboard';
  static const String parentDashboard = '/parent_dashboard';
  static const String accountantDashboard = '/accountant_dashboard';
  static const String secretaryDashboard = '/secretary_dashboard';
  static const String staffDashboard = '/staff_dashboard';

  static String getDashboardRoute(String role) {
    switch(role.toLowerCase()) {
      case 'admin': return adminDashboard;
      case 'teacher': return teacherDashboard;
      case 'parent': return parentDashboard;
      case 'accountant': return accountantDashboard;
      case 'secretary': return secretaryDashboard;
      case 'staff': return staffDashboard;
      default: return login;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    const supabaseUrl = 'https://nautmoivgssuuzvzlqgy.supabase.co'; 
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hdXRtb2l2Z3NzdXV6dnpscWd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwMjk2NzgsImV4cCI6MjA5NjYwNTY3OH0.FOWH8X-FM3p_VP7ewDF4efM6ja6nf3Ecw7_Rh4cTFPs';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  } catch (e) {
    debugPrint('Fatal: Supabase failed to initialize: $e');
  }

  final appSettings = AppSettings();
  await appSettings.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationService()),
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider(create: (_) => UpdateService()),
      ],
      child: const KagemaSchoolApp(),
    ),
  );
}

class KagemaSchoolApp extends StatelessWidget {
  const KagemaSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final auth = Provider.of<AuthenticationService>(context);

    return MaterialApp(
      title: 'Kagema school',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboard(), 
        AppRoutes.teacherDashboard: (context) => const TeacherDashboard(),
        AppRoutes.parentDashboard: (context) => ParentDashboard(parentPhone: auth.currentUserPhone ?? ''), 
        AppRoutes.accountantDashboard: (context) => const AccountantDashboard(),
        AppRoutes.secretaryDashboard: (context) => const SecretaryDashboard(),
        AppRoutes.staffDashboard: (context) => const StaffDashboard(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final role = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => _getDashboardByRole(role, auth.currentUserPhone),
          );
        }
        return null;
      },
    );
  }

  Widget _getDashboardByRole(String? role, String? phone) {
    switch(role?.toLowerCase()) {
      case 'admin': return const AdminDashboard();
      case 'teacher': return const TeacherDashboard();
      case 'parent': return ParentDashboard(parentPhone: phone ?? '');
      case 'accountant': return const AccountantDashboard();
      case 'secretary': return const SecretaryDashboard();
      case 'staff': return const StaffDashboard();
      default: return const LoginScreen();
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String statusMessage = "Initializing Neural Core...";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => statusMessage = "Establishing Cloud Handshake...");
    
    final auth = Provider.of<AuthenticationService>(context, listen: false);
    bool loggedIn = await auth.isAuthenticated(); 

    if (mounted) setState(() => statusMessage = "Neural Identity Verified. Welcome.");
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    
    if (loggedIn && auth.currentUserRole != null) {
       Navigator.pushReplacementNamed(context, AppRoutes.getDashboardRoute(auth.currentUserRole!));
    } else {
       Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      body: gemini?.buildCreativeBackground(
        isDark: true, // Always dark for splash
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              gemini?.buildGlowContainer(
                borderRadius: 50,
                borderThickness: 2,
                backgroundColor: theme.primaryColor.withOpacity(0.05),
                padding: const EdgeInsets.all(24),
                child: const Icon(Icons.school_rounded, size: 70, color: Colors.white),
              ) ?? const Icon(Icons.school_rounded, size: 70, color: Colors.white),
              const SizedBox(height: 32),
              const Text(
                'Kagema System',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              const Text(
                'NEURAL MANAGEMENT HUB',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 10),
              ),
              const SizedBox(height: 80),
              const SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                statusMessage.toUpperCase(),
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ) ?? const SizedBox(),
    );
  }
}
