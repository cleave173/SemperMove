import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

/// Провайдер для управления состоянием уведомлений
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _workoutRemindersEnabled = false;
  bool _waterRemindersEnabled = false;
  TimeOfDay _workoutTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoaded = false;

  bool get workoutRemindersEnabled => _workoutRemindersEnabled;
  bool get waterRemindersEnabled => _waterRemindersEnabled;
  TimeOfDay get workoutTime => _workoutTime;
  bool get isLoaded => _isLoaded;

  /// Загрузить сохраненные настройки
  Future<void> loadSettings() async {
    if (_isLoaded) return;
    _workoutRemindersEnabled = await _notificationService.isWorkoutEnabled;
    _waterRemindersEnabled = await _notificationService.isWaterEnabled;
    _workoutTime = await _notificationService.workoutTime;
    _isLoaded = true;
    notifyListeners();
  }

  /// Запрашивает разрешение на уведомления (Android 13+)
  /// Возвращает true если разрешение получено
  Future<bool> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    debugPrint('Notification permission result: $result');
    return result.isGranted;
  }

  /// Переключить напоминания о тренировках
  Future<void> toggleWorkoutReminders(bool enabled) async {
    if (enabled) {
      // Сначала запросить разрешение
      final granted = await _ensureNotificationPermission();
      if (!granted) {
        debugPrint('Notification permission denied — cannot enable workout reminders');
        return; // Не включаем если разрешение не дано
      }
    }

    _workoutRemindersEnabled = enabled;
    notifyListeners();

    if (enabled) {
      await _notificationService.scheduleWorkoutReminder(_workoutTime);
    } else {
      await _notificationService.cancelWorkoutReminders();
    }
  }

  /// Изменить время напоминания о тренировке
  Future<void> setWorkoutTime(TimeOfDay time) async {
    _workoutTime = time;
    notifyListeners();

    if (_workoutRemindersEnabled) {
      await _notificationService.scheduleWorkoutReminder(time);
    }
  }

  /// Переключить напоминания о воде
  Future<void> toggleWaterReminders(bool enabled) async {
    if (enabled) {
      final granted = await _ensureNotificationPermission();
      if (!granted) {
        debugPrint('Notification permission denied — cannot enable water reminders');
        return;
      }
    }

    _waterRemindersEnabled = enabled;
    notifyListeners();

    if (enabled) {
      await _notificationService.scheduleWaterReminders();
    } else {
      await _notificationService.cancelWaterReminders();
    }
  }
}
