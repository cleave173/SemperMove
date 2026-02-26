import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/pose_detection_service.dart';
import '../../services/step_tracker_service.dart';
import 'plank_timer_screen.dart';
import 'exercise_camera_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StepTrackerService _stepTracker = StepTrackerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().refreshUser();
    });

    // Запускаем трекинг шагов
    _stepTracker.onStepUpdate = (steps) {
      if (mounted) {
        setState(() {});
        // Автоматически обновляем шаги в Supabase каждые 50 шагов
        if (steps > 0 && steps % 50 == 0) {
          context.read<UserProvider>().updateProgress(dailySteps: steps);
        }
      }
    };
    _stepTracker.startTracking();
  }

  @override
  void dispose() {
    // Не вызываем _stepTracker.dispose() — он singleton, работает глобально
    super.dispose();
  }


  void _openPlankTimer() {
    final user = context.read<UserProvider>().user;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlankTimerScreen(currentSeconds: user?.plankSeconds ?? 0),
      ),
    );
  }

  void _openAITracking(ExerciseType type) {
    final user = context.read<UserProvider>().user;
    final currentCount = type == ExerciseType.pushUps
        ? (user?.pushUps ?? 0)
        : (user?.squats ?? 0);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseCameraScreen(
          exerciseType: type,
          currentCount: currentCount,
        ),
      ),
    ).then((_) {
      // Обновляем данные после возврата
      context.read<UserProvider>().refreshUser();
    });
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

    // Используем шаги из педометра если они больше сохранённых
    final pedometerSteps = _stepTracker.todaySteps;
    final savedSteps = user?.dailySteps ?? 0;
    final displaySteps = pedometerSteps > savedSteps ? pedometerSteps : savedSteps;

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
                              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 22),
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

                    // Steps card — с автоматическим обновлением от педометра
                    _buildStepsCard(loc, displaySteps, user?.stepsGoal ?? 10000),
                    const SizedBox(height: 12),

                    // Push-ups card — с кнопкой AI
                    _buildAIActivityCard(
                      loc.translate('push_ups'),
                      Icons.accessibility_new,
                      user?.pushUps ?? 0,
                      user?.pushUpsGoal ?? 100,
                      'push_ups',
                      loc.translate('times'),
                      ExerciseType.pushUps,
                    ),
                    const SizedBox(height: 12),

                    // Squats card — с кнопкой AI
                    _buildAIActivityCard(
                      loc.translate('squats'),
                      Icons.fitness_center,
                      user?.squats ?? 0,
                      user?.squatsGoal ?? 100,
                      'squats',
                      loc.translate('times'),
                      ExerciseType.squats,
                    ),
                    const SizedBox(height: 12),

                    // Plank — opens timer
                    GestureDetector(
                      onTap: _openPlankTimer,
                      child: _buildPlankCard(loc.translate('plank'), user?.plankSeconds ?? 0, user?.plankGoal ?? 300, loc.translate('sec')),
                    ),
                    const SizedBox(height: 12),
                    _buildWaterCard(loc, user?.waterMl ?? 0, user?.waterGoal ?? 2000),
                  ],
                ),
              ),
            ),
    );
  }

  /// Карточка шагов — показывает статус педометра
  Widget _buildStepsCard(AppLocalizations loc, int current, int goal) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

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
                  child: Icon(Icons.directions_walk, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(loc.translate('steps'), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          // Индикатор педометра
                          if (_stepTracker.isTracking)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sensors, size: 12, color: accentColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    'AUTO',
                                    style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$current / $goal',
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
      );
  }

  /// Карточка упражнения с кнопкой AI-трекинга
  Widget _buildAIActivityCard(String title, IconData icon, int current, int goal, String category, String unit, ExerciseType exerciseType) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final loc = AppLocalizations.of(context);

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
              // Кнопка AI-трекинга
              GestureDetector(
                onTap: () => _openAITracking(exerciseType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withOpacity(0.25), accentColor.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, color: accentColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        loc.translate('start_tracking'),
                        style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
    );
  }

  /// Добавить 100 мл воды
  Future<void> _addWater100ml() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final loc = AppLocalizations.of(context);
    final accentColor = Theme.of(context).colorScheme.primary;

    try {
      final newValue = user.waterMl + 100;
      await context.read<UserProvider>().updateProgress(waterMl: newValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('+100 ${loc.translate("ml")}'),
              ],
            ),
            backgroundColor: accentColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Показать слайдер для выбора объёма воды
  Future<void> _showWaterSliderDialog() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final loc = AppLocalizations.of(context);
    final accentColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    double selectedMl = 250;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          title: Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue.shade300),
              const SizedBox(width: 8),
              Text(
                loc.translate('add_water'),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${selectedMl.toInt()} ${loc.translate("ml")}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: accentColor.withOpacity(0.2),
                  thumbColor: accentColor,
                  overlayColor: accentColor.withOpacity(0.1),
                ),
                child: Slider(
                  value: selectedMl,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '${selectedMl.toInt()} ${loc.translate("ml")}',
                  onChanged: (value) {
                    setDialogState(() => selectedMl = value);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('50 ${loc.translate("ml")}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                  Text('1000 ${loc.translate("ml")}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF888888))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedMl.toInt()),
              child: Text(loc.translate('add'), style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result != null && result > 0) {
      try {
        final newValue = user.waterMl + result;
        await context.read<UserProvider>().updateProgress(waterMl: newValue);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('+$result ${loc.translate("ml")}'),
                ],
              ),
              backgroundColor: accentColor,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Карточка воды с двумя кнопками
  Widget _buildWaterCard(AppLocalizations loc, int current, int goal) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop, color: Colors.blue.shade300, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.translate('water'), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$current ${loc.translate("ml")} / $goal',
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
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.blue.shade300 : Colors.blue.shade300.withOpacity(0.7)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          // Две кнопки
          Row(
            children: [
              // Кнопка +100 мл
              Expanded(
                child: GestureDetector(
                  onTap: _addWater100ml,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.blue.shade300, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          loc.translate('quick_add'),
                          style: TextStyle(color: Colors.blue.shade300, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Кнопка с выбором
              Expanded(
                child: GestureDetector(
                  onTap: _showWaterSliderDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune, color: Colors.blue.shade300, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          loc.translate('custom_amount'),
                          style: TextStyle(color: Colors.blue.shade300, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
