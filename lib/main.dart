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
    // Wrap Supabase in try-catch to prevent hang if URL is invalid
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co', // Use valid format even if placeholder
        anonKey: 'sb_publishable_placeholder', 
      );
    } catch (e) {
      debugPrint('Supabase initialization bypassed: $e');
    }

    final appSettings = AppSettings();
    await appSettings.loadSettings();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthenticationService()),
          ChangeNotifierProvider.value(value: appSettings),
        ],
        child: const KagemaSchoolApp(),
      ),
    );
  } catch (e) {
    debugPrint('Fatal Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        AppRoutes.adminDashboard: (context) => const TeacherDashboard(), // Redirect for debugging if needed
        AppRoutes.teacherDashboard: (context) => const TeacherDashboard(),
        AppRoutes.parentDashboard: (context) => ParentDashboard(parentPhone: auth.currentUserPhone ?? ''), 
        AppRoutes.accountantDashboard: (context) => const AccountantDashboard(),
        AppRoutes.secretaryDashboard: (context) => const SecretaryDashboard(),
        AppRoutes.staffDashboard: (context) => const StaffDashboard(),
      },

      // Standard route mapping for Admin
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.adminDashboard) {
           return MaterialPageRoute(builder: (_) => const AdminDashboard());
        }
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
  String statusMessage = "Initializing Intelligent Systems...";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => statusMessage = "Syncing School Protocol...");
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final updateService = UpdateService();
    await updateService.init();

    final auth = Provider.of<AuthenticationService>(context, listen: false);
    await auth.isAuthenticated(); // Restore session if exists

    if (mounted) setState(() => statusMessage = "System Verified. Welcome.");
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    
    // Check if already logged in
    if (auth.currentUserRole != null) {
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gemini?.primaryGradient ?? const LinearGradient(
            colors: [Color(0xFFD84315), Color(0xFFBF360C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Kagema school',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'MANAGEMENT SYSTEM',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10),
            ),
            const SizedBox(height: 60),
            _buildPulseIndicator(),
            const SizedBox(height: 24),
            Text(
              statusMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('404 - Page Not Found', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
