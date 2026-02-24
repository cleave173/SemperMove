import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import 'plank_timer_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // User data is already loaded in SplashScreen or Login/Register
    // But we can refresh it just in case
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().refreshUser();
    });
  }

  Future<void> _showUpdateDialog(String category, int currentValue) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue.toString());
    final accentColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(category, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel, style: TextStyle(color: const Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text) ?? currentValue),
            child: Text(loc.save, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updates = <String, dynamic>{};
        switch (category) {
          case 'steps': updates['daily_steps'] = result; break;
          case 'push_ups': updates['push_ups'] = result; break;
          case 'squats': updates['squats'] = result; break;
          case 'water': updates['water_ml'] = result; break;
        }

        await context.read<UserProvider>().updateProgress(
          dailySteps: updates['daily_steps'],
          pushUps: updates['push_ups'],
          squats: updates['squats'],
          waterMl: updates['water_ml'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.progressUpdated),
              backgroundColor: accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openPlankTimer() {
    final user = context.read<UserProvider>().user;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlankTimerScreen(currentSeconds: user?.plankSeconds ?? 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isLoading = userProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.semperMove,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF333333),
            fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1,
          ),
        ),
        actions: [

          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : const Color(0xFF333333)),
            onPressed: () => context.read<UserProvider>().refreshUser(),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : RefreshIndicator(
              color: accentColor,
              onRefresh: () => context.read<UserProvider>().refreshUser(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting + Streak
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.translate('hello')}, ${user?.username ?? ''}!',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF333333),
                                  fontSize: 24, fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.todayActivity,
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        // Streak badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orangeAccent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Text(
                                '${user?.currentStreak ?? 0} ${loc.days}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Activity cards
                    _buildActivityCard(loc.translate('steps'), Icons.directions_walk, user?.dailySteps ?? 0, user?.stepsGoal ?? 10000, 'steps', ''),
                    const SizedBox(height: 12),
                    _buildActivityCard(loc.translate('push_ups'), Icons.accessibility_new, user?.pushUps ?? 0, user?.pushUpsGoal ?? 100, 'push_ups', loc.translate('times')),
                    const SizedBox(height: 12),
                    _buildActivityCard(loc.translate('squats'), Icons.fitness_center, user?.squats ?? 0, user?.squatsGoal ?? 100, 'squats', loc.translate('times')),
                    const SizedBox(height: 12),
                    // Plank — opens timer instead of dialog
                    GestureDetector(
                      onTap: _openPlankTimer,
                      child: _buildPlankCard(loc.translate('plank'), user?.plankSeconds ?? 0, user?.plankGoal ?? 300, loc.translate('sec')),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(loc.translate('water'), Icons.water_drop, user?.waterMl ?? 0, user?.waterGoal ?? 2000, 'water', loc.translate('ml')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityCard(String title, IconData icon, int current, int goal, String category, String unit) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;


    return GestureDetector(
      onTap: () => _showUpdateDialog(category, current),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '$current${unit.isNotEmpty ? ' $unit' : ''} / $goal',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: progress >= 1.0 ? accentColor : (isDark ? Colors.white : const Color(0xFF333333)),
                    fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? accentColor : accentColor.withOpacity(0.7)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlankCard(String title, int current, int goal, String unit) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final minutes = current ~/ 60;
    final secs = current % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.timer, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$timeStr / ${goal ~/ 60}:${(goal % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: accentColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context).translate('timer_title').toUpperCase(),
                      style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? accentColor : accentColor.withOpacity(0.7)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
