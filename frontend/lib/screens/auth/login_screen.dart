import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Слушаем PASSWORD_RECOVERY — если пользователь перешёл по ссылке сброса
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Load user data before navigation
        await context.read<UserProvider>().loadUser();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        String message;
        if (e is AuthException) {
          switch (e.statusCode?.toString()) {
            case '400':
              message = loc.translate('error_invalid_credentials');
              break;
            case '422':
              message = loc.translate('error_email_not_confirmed');
              break;
            case '429':
              message = loc.translate('error_too_many_requests');
              break;
            default:
              message = loc.translate('error_login_failed');
          }
        } else {
          message = loc.translate('error_network');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final hintColor = const Color(0xFF888888);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'SEMPER MOVE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold,
                      color: textColor, letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.moveToVictory,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: accentColor, letterSpacing: 1),
                  ),
                  const SizedBox(height: 48),

                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: loc.translate('email'),
                      labelStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.email, color: accentColor),
                      filled: true, fillColor: cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return loc.translate('enter_email');
                      if (!value.contains('@')) return loc.translate('enter_valid_email');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: textColor),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('password'),
                      labelStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.lock, color: accentColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: hintColor,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true, fillColor: cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return loc.translate('enter_password');
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(loc.login, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Забыли пароль?
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: Text(
                        loc.translate('forgot_password'),
                        style: TextStyle(color: hintColor, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(loc.translate('no_account'), style: TextStyle(color: hintColor)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(loc.register, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
