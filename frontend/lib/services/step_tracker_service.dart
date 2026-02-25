import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для автоматического подсчёта шагов через нативные сенсоры телефона.
///
/// Использует пакет `pedometer`, который работает через акселерометр.
/// Хранит начальное значение счётчика при первом запуске за день
/// в SharedPreferences, чтобы подсчитать шаги именно за сегодня.
class StepTrackerService {
  static final StepTrackerService _instance = StepTrackerService._internal();
  factory StepTrackerService() => _instance;
  StepTrackerService._internal();

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  int _todaySteps = 0;
  int _initialSteps = 0;
  bool _isTracking = false;
  String _pedestrianStatus = 'unknown';

  /// Callback при обновлении шагов
  void Function(int steps)? onStepUpdate;

  /// Callback при изменении статуса (walking / stopped)
  void Function(String status)? onStatusUpdate;

  int get todaySteps => _todaySteps;
  bool get isTracking => _isTracking;
  String get pedestrianStatus => _pedestrianStatus;

  /// Начать отслеживание шагов
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // Загружаем сохранённые данные за сегодня
      await _loadTodayData();

      // Подписка на подсчёт шагов
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepError,
        cancelOnError: false,
      );

      // Подписка на статус (ходьба/стоит)
      _statusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: (e) => debugPrint('Pedestrian status error: $e'),
        cancelOnError: false,
      );

      _isTracking = true;
    } catch (e) {
      debugPrint('Step tracking error: $e');
    }
  }

  /// Остановить отслеживание
  void stopTracking() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _isTracking = false;
  }

  void _onStepCount(StepCount event) async {
    final totalSteps = event.steps;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('step_tracker_date') ?? '';

    if (savedDate != today) {
      // Новый день — сбрасываем начальное значение
      _initialSteps = totalSteps;
      await prefs.setString('step_tracker_date', today);
      await prefs.setInt('step_tracker_initial', totalSteps);
      _todaySteps = 0;
    } else {
      _initialSteps = prefs.getInt('step_tracker_initial') ?? totalSteps;
      _todaySteps = totalSteps - _initialSteps;
    }

    if (_todaySteps < 0) _todaySteps = 0;

    // Сохраняем текущее значение шагов
    await prefs.setInt('step_tracker_today_steps', _todaySteps);

    onStepUpdate?.call(_todaySteps);
  }

  void _onStepError(dynamic error) {
    debugPrint('Step count error: $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _pedestrianStatus = event.status;
    onStatusUpdate?.call(_pedestrianStatus);
  }

  Future<void> _loadTodayData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('step_tracker_date') ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate == today) {
      _todaySteps = prefs.getInt('step_tracker_today_steps') ?? 0;
      _initialSteps = prefs.getInt('step_tracker_initial') ?? 0;
    } else {
      _todaySteps = 0;
      _initialSteps = 0;
    }
  }

  /// Получить сохранённые шаги за сегодня (для использования без стрима)
  Future<int> getSavedTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('step_tracker_date') ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate == today) {
      return prefs.getInt('step_tracker_today_steps') ?? 0;
    }
    return 0;
  }

  /// Освобождение ресурсов
  void dispose() {
    stopTracking();
  }
}
