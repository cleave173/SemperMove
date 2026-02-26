import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.resetPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            padding: const EdgeInsets.all(24),
            child: _emailSent ? _buildSuccessView(loc, accentColor, textColor, hintColor) : _buildFormView(loc, accentColor, cardColor, borderColor, textColor, hintColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(AppLocalizations loc, Color accent, Color text, Color hint) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mark_email_read, size: 64, color: accent),
        ),
        const SizedBox(height: 32),
        Text(
          loc.translate('email_sent'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text),
        ),
        const SizedBox(height: 16),
        Text(
          loc.translate('check_email_for_reset'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: hint, height: 1.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _emailController.text.trim(),
            style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('back_to_login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(AppLocalizations loc, Color accent, Color card, Color border, Color text, Color hint) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset, size: 72, color: accent),
          const SizedBox(height: 24),
          Text(
            loc.translate('forgot_password'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: text),
          ),
          const SizedBox(height: 12),
          Text(
            loc.translate('forgot_password_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: hint, height: 1.5),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              labelText: loc.translate('email'),
              labelStyle: TextStyle(color: hint),
              prefixIcon: Icon(Icons.email, color: accent),
              filled: true,
              fillColor: card,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 2),
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
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(loc.translate('send_reset_link'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
