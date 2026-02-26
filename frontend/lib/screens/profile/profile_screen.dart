import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabaseService = SupabaseService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _supabaseService.getProfile();
      setState(() { _user = user; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;

    try {
      final url = await _supabaseService.uploadAvatar(File(picked.path));
      setState(() { _user = _user?.copyWith(avatarUrl: url); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }



  Future<void> _logout() async {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(loc.translate('logout'), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(loc.translate('logout_confirm'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF888888)))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.translate('exit'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (_) => false,
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
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textColor = isDark ? Colors.white : const Color(0xFF333333);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(loc.translate('profile_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout),
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          IconButton(icon: Icon(Icons.refresh, color: textColor), onPressed: _loadProfile),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : RefreshIndicator(
              color: accentColor,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: accentColor.withOpacity(0.2),
                            backgroundImage: _user?.avatarUrl != null
                                ? NetworkImage(_user!.avatarUrl!)
                                : null,
                            child: _user?.avatarUrl == null
                                ? Icon(Icons.person, size: 55, color: accentColor)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF0A0A0A) : Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_user?.username ?? '', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_user?.email ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
                    const SizedBox(height: 8),
                    // Streak
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${_user?.currentStreak ?? 0} ${loc.days} ${loc.streak.toLowerCase()}',
                            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats cards
                    _buildStatCard(loc.translate('steps'), '${_user?.dailySteps ?? 0}', Icons.directions_walk, accentColor, cardColor, borderColor, textColor),
                    const SizedBox(height: 8),
                    _buildStatCard(loc.translate('push_ups'), '${_user?.pushUps ?? 0} ${loc.translate('times')}', Icons.accessibility_new, accentColor, cardColor, borderColor, textColor),
                    const SizedBox(height: 8),
                    _buildStatCard(loc.translate('squats'), '${_user?.squats ?? 0} ${loc.translate('times')}', Icons.fitness_center, accentColor, cardColor, borderColor, textColor),
                    const SizedBox(height: 8),
                    _buildStatCard(loc.translate('plank'), '${_user?.plankSeconds ?? 0} ${loc.translate('sec')}', Icons.timer, accentColor, cardColor, borderColor, textColor),
                    const SizedBox(height: 8),
                    _buildStatCard(loc.translate('water'), '${_user?.waterMl ?? 0} ${loc.translate('ml')}', Icons.water_drop, accentColor, cardColor, borderColor, textColor),
                    
                    const SizedBox(height: 24),


                    const SizedBox(height: 24),
                    // Achievements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.translate('achievements'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              _badge(loc.translate('master'), loc.translate('hundred_pushups'), Icons.fitness_center, isUnlocked: (_user?.pushUps ?? 0) >= 100, accentColor: accentColor, isDark: isDark),
                              _badge(loc.translate('athlete'), loc.translate('hundred_squats'), Icons.accessibility_new, isUnlocked: (_user?.squats ?? 0) >= 100, accentColor: accentColor, isDark: isDark),
                              _badge(loc.translate('iron'), loc.translate('five_min_plank'), Icons.timer, isUnlocked: (_user?.plankSeconds ?? 0) >= 300, accentColor: accentColor, isDark: isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accent, Color card, Color border, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: text, fontSize: 15)),
          const Spacer(),
          Text(value, style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _badge(String title, String desc, IconData icon, {required bool isUnlocked, required Color accentColor, required bool isDark}) {
    return Container(
      width: 100, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? accentColor.withOpacity(0.1) : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? accentColor : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0))),
      ),
      child: Column(
        children: [
          Icon(icon, color: isUnlocked ? accentColor : const Color(0xFF444444), size: 32),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: isUnlocked ? accentColor : const Color(0xFF444444), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(color: isUnlocked ? const Color(0xFF888888) : const Color(0xFF444444), fontSize: 10)),
        ],
      ),
    );
  }
}
