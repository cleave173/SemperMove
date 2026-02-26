import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_logger.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logger.info('App', '========== SemperMove starting ==========');

  // Supabase — с deep link для сброса пароля
  try {
    await Supabase.initialize(
      url: 'https://uahgtpjqeswqnptokqjc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhaGd0cGpxZXN3cW5wdG9rcWpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyNjIzMjYsImV4cCI6MjA4NTgzODMyNn0.s0ysAH6b_AphRIjmNKTuFh0PWjvlgQRgfokfUun54q0',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    logger.test('Supabase connection', true, details: 'initialized with PKCE');
  } catch (e) {
    logger.error('App', 'Supabase init failed', e);
  }

  // Уведомления
  try {
    await NotificationService().init();
    logger.test('Notifications', true, details: 'service initialized');
    await NotificationService().scheduleActivityReminders();
    logger.info('App', 'Activity reminders scheduled');
  } catch (e) {
    logger.error('App', 'Notification init failed (non-critical)', e);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const SemperMoveApp(),
    ),
  );
}

class SemperMoveApp extends StatelessWidget {
  const SemperMoveApp({super.key});

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    primaryColor: const Color(0xFF00FF88),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF88),
      secondary: Color(0xFF00FF88),
      surface: Color(0xFF1A1A1A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFF888888)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF88),
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF888888)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    primaryColor: const Color(0xFF00CC6A),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00CC6A),
      secondary: Color(0xFF00CC6A),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF333333)),
      titleTextStyle: TextStyle(
        color: Color(0xFF333333),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF333333)),
      bodyMedium: TextStyle(color: Color(0xFF333333)),
      bodySmall: TextStyle(color: Color(0xFF888888)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00CC6A),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00CC6A), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF888888)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        final isDark = themeProvider.isDark;

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'Semper Move',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: LocaleProvider.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
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
  @override
  void initState() {
    super.initState();

    // Слушаем событие PASSWORD_RECOVERY от Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      logger.info('Auth', 'Auth event: ${data.event}');
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        logger.action('Auth', 'Password recovery event — opening reset screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
        await context.read<UserProvider>().loadUser();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => session != null
              ? MainScreen()
              : LoginScreen(),
        ),
      );
    }
  }

  // Reload user data when this widget is initialized
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.1),
                border: Border.all(color: accentColor, width: 3),
              ),
              child: Icon(Icons.fitness_center, size: 80, color: accentColor),
            ),
            const SizedBox(height: 32),
            Text(
              'SEMPER MOVE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF333333),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).moveToVictory,
              style: TextStyle(
                fontSize: 16,
                color: accentColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: accentColor, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
