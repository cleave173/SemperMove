import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';

enum PlankMode { stopwatch, timer }

class PlankTimerScreen extends StatefulWidget {
  final int currentSeconds;
  const PlankTimerScreen({super.key, required this.currentSeconds});

  @override
  State<PlankTimerScreen> createState() => _PlankTimerScreenState();
}

class _PlankTimerScreenState extends State<PlankTimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  int _timerGoal = 60; // countdown start value
  bool _isRunning = false;
  bool _isSaving = false;
  PlankMode _mode = PlankMode.stopwatch;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<int> _presetSeconds = [30, 60, 90, 120, 180, 300];

  @override
  void initState() {
    super.initState();
    _seconds = 0;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_mode == PlankMode.timer && _seconds <= 0) {
      _seconds = _timerGoal;
    }
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_mode == PlankMode.stopwatch) {
          _seconds++;
        } else {
          _seconds--;
          if (_seconds <= 0) {
            _seconds = 0;
            _stopTimer();
          }
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _seconds = _mode == PlankMode.timer ? _timerGoal : 0;
    });
  }

  int get _totalElapsed {
    if (_mode == PlankMode.stopwatch) return _seconds;
    return _timerGoal - _seconds; // how much time passed in countdown
  }

  Future<void> _saveAndExit() async {
    _stopTimer();
    setState(() => _isSaving = true);

    final saveSeconds = widget.currentSeconds + _totalElapsed;

    try {
      await context.read<UserProvider>().updateProgress(
        plankSeconds: saveSeconds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).progressUpdated),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, saveSeconds);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _switchMode(PlankMode mode) {
    if (_isRunning) return;
    setState(() {
      _mode = mode;
      _seconds = mode == PlankMode.timer ? _timerGoal : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final loc = AppLocalizations.of(context);

    final userProvider = Provider.of<UserProvider>(context);
    final goal = userProvider.user?.plankGoal ?? 300;

    // Progress based on total elapsed
    double progress;
    if (_mode == PlankMode.stopwatch) {
      progress = goal > 0 ? (_seconds / goal).clamp(0.0, 1.0) : 0.0;
    } else {
      final elapsed = _timerGoal - _seconds;
      progress = _timerGoal > 0 ? (elapsed / _timerGoal).clamp(0.0, 1.0) : 0.0;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('plank'),
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mode selector
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeTab(
                        icon: Icons.timer_outlined,
                        label: loc.translate('stopwatch'),
                        isSelected: _mode == PlankMode.stopwatch,
                        onTap: () => _switchMode(PlankMode.stopwatch),
                        accentColor: accentColor,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                      _modeTab(
                        icon: Icons.hourglass_bottom,
                        label: loc.translate('timer_mode'),
                        isSelected: _mode == PlankMode.timer,
                        onTap: () => _switchMode(PlankMode.timer),
                        accentColor: accentColor,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Timer presets (only in timer mode)
                if (_mode == PlankMode.timer && !_isRunning) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _presetSeconds.map((s) {
                      final isSelected = _timerGoal == s;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _timerGoal = s;
                            _seconds = s;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? accentColor : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0))),
                          ),
                          child: Text(
                            _formatTime(s),
                            style: TextStyle(
                              color: isSelected ? Colors.black : textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Timer circle
                ScaleTransition(
                  scale: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRunning
                            ? [accentColor, accentColor.withOpacity(0.6)]
                            : [
                                isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                              ],
                      ),
                      boxShadow: [
                        if (_isRunning)
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_seconds),
                          style: TextStyle(
                            color: _isRunning ? Colors.black : textColor,
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        if (_mode == PlankMode.stopwatch)
                          Text(
                            loc.translate('stopwatch'),
                            style: TextStyle(
                              color: _isRunning ? Colors.black54 : const Color(0xFF888888),
                              fontSize: 12,
                            ),
                          ),
                        if (_mode == PlankMode.timer)
                          Text(
                            loc.translate('timer_mode'),
                            style: TextStyle(
                              color: _isRunning ? Colors.black54 : const Color(0xFF888888),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Progress bar
                if (_mode == PlankMode.timer) ...[
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                        valueColor: AlwaysStoppedAnimation(accentColor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    '${_totalElapsed} / $goal ${loc.translate('sec')}',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: goal > 0 ? (_seconds / goal).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                        valueColor: AlwaysStoppedAnimation(accentColor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],

                if (_mode == PlankMode.timer && _seconds == 0 && _timerGoal > 0 && !_isRunning && _totalElapsed > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '🎉 ${loc.translate('goal_reached')}!',
                      style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 40),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleButton(
                      icon: Icons.refresh,
                      color: const Color(0xFF888888),
                      onTap: _resetTimer,
                      size: 56,
                    ),
                    const SizedBox(width: 24),
                    _circleButton(
                      icon: _isRunning ? Icons.pause : Icons.play_arrow,
                      color: _isRunning ? Colors.redAccent : accentColor,
                      onTap: _isRunning ? _stopTimer : _startTimer,
                      size: 80,
                    ),
                    const SizedBox(width: 24),
                    _circleButton(
                      icon: Icons.save,
                      color: accentColor,
                      onTap: _isSaving ? null : _saveAndExit,
                      size: 56,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.translate('reset'), style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    const SizedBox(width: 70),
                    Text(
                      _isRunning ? loc.translate('stop') : loc.translate('start'),
                      style: TextStyle(color: _isRunning ? Colors.redAccent : accentColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 60),
                    Text(loc.save, style: TextStyle(color: accentColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required Color textColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : const Color(0xFF888888), size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF888888),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
