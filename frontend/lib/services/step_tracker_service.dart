import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для автоматического подсчёта шагов через нативные сенсоры телефона.
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

  /// Начать отслеживание шагов (с запросом разрешения)
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // Запрашиваем разрешения (обязательно на Android 10+)
      final activityStatus = await Permission.activityRecognition.request();
      final sensorsStatus = await Permission.sensors.request();

      if (!activityStatus.isGranted && !sensorsStatus.isGranted) {
        debugPrint('Pedometer permissions denied (activity: $activityStatus, sensors: $sensorsStatus)');
        return;
      }

      // Загружаем сохранённые данные за сегодня
      await _loadTodayData();

      // Подписка на подсчёт шагов
      _stepSubscription?.cancel();
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) {
          debugPrint('Step count error: $error — restarting in 5s');
          // Перезапускаем подписку через 5 секунд
          Future.delayed(const Duration(seconds: 5), () {
            _stepSubscription?.cancel();
            _stepSubscription = Pedometer.stepCountStream.listen(
              _onStepCount,
              onError: _onStepError,
              cancelOnError: false,
            );
          });
        },
        cancelOnError: false,
      );

      // Подписка на статус (ходьба/стоит)
      _statusSubscription?.cancel();
      _statusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: (e) => debugPrint('Pedestrian status error: $e'),
        cancelOnError: false,
      );

      _isTracking = true;
      debugPrint('Step tracking started successfully');
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
