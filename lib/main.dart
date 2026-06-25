import 'package:flutter/gestures.dart';
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
import 'services/event_handler_service.dart';
import 'app_theme.dart';
import 'app_settings.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
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
        ChangeNotifierProvider(create: (_) => EventHandlerService()),
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
      scrollBehavior: MyCustomScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/teacher_dashboard': (context) => const TeacherDashboard(),
        '/parent_dashboard': (context) => ParentDashboard(parentPhone: auth.currentUserPhone ?? ''),
        '/accountant_dashboard': (context) => const AccountantDashboard(),
        '/secretary_dashboard': (context) => const SecretaryDashboard(),
        '/staff_dashboard': (context) => StaffDashboard(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String statusMessage = "Starting System...";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final auth = Provider.of<AuthenticationService>(context, listen: false);
    bool loggedIn = await auth.isAuthenticated();
    if (loggedIn && auth.currentUserRole != null) {
       Navigator.pushReplacementNamed(context, '/${auth.currentUserRole}_dashboard');
    } else {
       Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme safely
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    // If gemini is null, use a simple fallback
    if (gemini == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/kagema_logo.png',
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.school_rounded, size: 70, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'Kagema System',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 80),
              const CircularProgressIndicator(color: Colors.white70),
              const SizedBox(height: 32),
              Text(
                statusMessage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If gemini exists, use it
    return Scaffold(
      body: gemini.buildCreativeBackground(
        isDark: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/kagema_logo.png',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.school_rounded, size: 70, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Kagema System',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 80),
              const CircularProgressIndicator(color: Colors.white70),
              const SizedBox(height: 32),
              Text(
                statusMessage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}