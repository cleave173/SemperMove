import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context);

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('passwords_no_match')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabaseService.signUp(
        _emailController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('registration_success')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Load user data 
        await context.read<UserProvider>().loadUser();

        if (mounted) {
           Navigator.of(context).pop(); 
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is AuthException && e.message == 'confirm_email') {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(loc.translate('confirm_email_title')),
              content: Text(loc.translate('confirm_email_body')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to login
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final hintColor = const Color(0xFF888888);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                   Text(
                    loc.translate('registration'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('create_account'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: hintColor),
                  ),
                  const SizedBox(height: 40),

                  _buildField(_emailController, loc.translate('email'), Icons.email, accentColor, cardColor, borderColor, textColor, hintColor,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.translate('enter_email');
                      if (!v.contains('@')) return loc.translate('enter_valid_email');
                      return null;
                    }),
                  const SizedBox(height: 16),

                  _buildField(_usernameController, loc.translate('username'), Icons.person, accentColor, cardColor, borderColor, textColor, hintColor,
                    validator: (v) => (v == null || v.isEmpty) ? loc.translate('enter_username') : null),
                  const SizedBox(height: 16),

                  _buildField(_passwordController, loc.translate('password'), Icons.lock, accentColor, cardColor, borderColor, textColor, hintColor,
                    obscure: _obscurePassword,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.translate('enter_password');
                      if (v.length < 6) return loc.translate('password_min');
                      return null;
                    }),
                  const SizedBox(height: 16),

                  _buildField(_confirmPasswordController, loc.translate('confirm_password'), Icons.lock_outline, accentColor, cardColor, borderColor, textColor, hintColor,
                    obscure: _obscureConfirmPassword,
                    onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    validator: (v) => (v == null || v.isEmpty) ? loc.translate('confirm_your_password') : null),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(loc.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color accent, Color fill, Color border, Color text, Color hint, {
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: text),
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hint),
        prefixIcon: Icon(icon, color: accent),
        suffixIcon: onToggle != null ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: hint),
          onPressed: onToggle,
        ) : null,
        filled: true, fillColor: fill,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
