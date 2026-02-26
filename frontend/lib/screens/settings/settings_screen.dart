import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notification settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadSettings();
    });
  }

  Future<void> _showGoalsDialog() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user == null) return;
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final stepsC = TextEditingController(text: user.stepsGoal.toString());
    final pushC = TextEditingController(text: user.pushUpsGoal.toString());
    final squatsC = TextEditingController(text: user.squatsGoal.toString());
    final plankC = TextEditingController(text: user.plankGoal.toString());
    final waterC = TextEditingController(text: user.waterGoal.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(loc.translate('set_goals'), style: TextStyle(color: textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _goalField(stepsC, loc.translate('steps_goal'), textColor, isDark, accentColor),
              _goalField(pushC, loc.translate('pushups_goal'), textColor, isDark, accentColor),
              _goalField(squatsC, loc.translate('squats_goal'), textColor, isDark, accentColor),
              _goalField(plankC, loc.translate('plank_goal'), textColor, isDark, accentColor),
              _goalField(waterC, loc.translate('water_goal'), textColor, isDark, accentColor),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF888888)))),
          TextButton(
            onPressed: () async {
              try {
                await userProvider.updateGoals(
                  stepsGoal: int.tryParse(stepsC.text),
                  pushUpsGoal: int.tryParse(pushC.text),
                  squatsGoal: int.tryParse(squatsC.text),
                  plankGoal: int.tryParse(plankC.text),
                  waterGoal: int.tryParse(waterC.text),
                );
                
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(loc.save, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _goalField(TextEditingController c, String label, Color textColor, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF888888)),
          filled: true,
          fillColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _pickWorkoutTime() async {
    final notifProvider = context.read<NotificationProvider>();
    final picked = await showTimePicker(
      context: context,
      initialTime: notifProvider.workoutTime,
    );
    if (picked != null) {
      await notifProvider.setWorkoutTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(loc.translate('settings_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                Icon(Icons.dark_mode, color: accentColor),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.translate('dark_theme'), style: TextStyle(color: textColor, fontSize: 16))),
                Switch(
                  value: themeProvider.isDark,
                  activeColor: accentColor,
                  onChanged: (_) => themeProvider.toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Language
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: accentColor),
                    const SizedBox(width: 12),
                    Text(loc.translate('language'), style: TextStyle(color: textColor, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: LocaleProvider.supportedLocales.map((locale) {
                    final isSelected = localeProvider.locale.languageCode == locale.languageCode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => localeProvider.setLocale(locale),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? accentColor : borderColor),
                          ),
                          child: Text(
                            LocaleProvider.localeNames[locale.languageCode] ?? locale.languageCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.black : textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Goals
          GestureDetector(
            onTap: _showGoalsDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
              child: Row(
                children: [
                  Icon(Icons.flag, color: accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.goals, style: TextStyle(color: textColor, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(loc.translate('set_goals'), style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: const Color(0xFF888888)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ==================== NOTIFICATIONS ====================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: accentColor),
                    const SizedBox(width: 12),
                    Text(loc.translate('notifications'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                // Workout reminders
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(loc.translate('workout_reminders'), style: TextStyle(color: textColor, fontSize: 14))),
                    Switch(
                      value: notifProvider.workoutRemindersEnabled,
                      activeColor: accentColor,
                      onChanged: (val) => notifProvider.toggleWorkoutReminders(val),
                    ),
                  ],
                ),

                // Workout time picker
                if (notifProvider.workoutRemindersEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 30, bottom: 8),
                    child: GestureDetector(
                      onTap: _pickWorkoutTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: accentColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${loc.translate('reminder_time')}: ${notifProvider.workoutTime.format(context)}',
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const Divider(height: 1, color: Color(0xFF2A2A2A)),
                const SizedBox(height: 8),

                // Water reminders
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(loc.translate('water_reminders'), style: TextStyle(color: textColor, fontSize: 14))),
                    Switch(
                      value: notifProvider.waterRemindersEnabled,
                      activeColor: accentColor,
                      onChanged: (val) => notifProvider.toggleWaterReminders(val),
                    ),
                  ],
                ),

                if (notifProvider.waterRemindersEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      loc.translate('water_reminder_schedule'),
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  elevation: 0,
              ),
              onPressed: () async {
                 await userProvider.signOut();
                 if (mounted) {
                   Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                 }
              }, 
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}

