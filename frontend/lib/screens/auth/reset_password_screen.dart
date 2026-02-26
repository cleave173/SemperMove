import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';

/// Экран ввода нового пароля (после перехода по ссылке из email)
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context);

    if (_passwordController.text != _confirmController.text) {
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
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('password_updated')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Возвращаем на логин
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('error')}: $e'),
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
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset, size: 80, color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('new_password_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('new_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: hintColor),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure1,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: loc.translate('new_password'),
                      labelStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.lock, color: accentColor),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: hintColor),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
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
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.translate('enter_password');
                      if (v.length < 6) return loc.translate('password_too_short');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscure2,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: loc.translate('confirm_password'),
                      labelStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: hintColor),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
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
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return loc.translate('enter_password');
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(
                              loc.translate('save_new_password'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
