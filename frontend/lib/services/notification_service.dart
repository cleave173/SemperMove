import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис локальных push-уведомлений
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification channel IDs
  static const _workoutChannelId = 'workout_reminders';
  static const _waterChannelId = 'water_reminders';
  static const _duelChannelId = 'duel_notifications';

  // Notification IDs
  static const _workoutNotificationId = 100;
  static const _waterBaseNotificationId = 200; // 200-207 for water reminders
  static const _duelNotificationId = 300;

  // SharedPreferences keys
  static const _keyWorkoutEnabled = 'notif_workout_enabled';
  static const _keyWaterEnabled = 'notif_water_enabled';
  static const _keyWorkoutHour = 'notif_workout_hour';
  static const _keyWorkoutMinute = 'notif_workout_minute';

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Request iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;

    // Restore scheduled notifications from saved preferences
    await _restoreScheduledNotifications();
  }

  Future<void> _restoreScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutEnabled = prefs.getBool(_keyWorkoutEnabled) ?? false;
    final waterEnabled = prefs.getBool(_keyWaterEnabled) ?? false;

    if (workoutEnabled) {
      final hour = prefs.getInt(_keyWorkoutHour) ?? 9;
      final minute = prefs.getInt(_keyWorkoutMinute) ?? 0;
      await scheduleWorkoutReminder(TimeOfDay(hour: hour, minute: minute));
    }

    if (waterEnabled) {
      await scheduleWaterReminders();
    }
  }

  // ==================== WORKOUT REMINDERS ====================

  Future<void> scheduleWorkoutReminder(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWorkoutEnabled, true);
    await prefs.setInt(_keyWorkoutHour, time.hour);
    await prefs.setInt(_keyWorkoutMinute, time.minute);

    await _plugin.cancel(_workoutNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _workoutNotificationId,
      '💪 Время тренировки!',
      'Не забудь сделать тренировку сегодня! Двигайся к победе!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _workoutChannelId,
          'Напоминания о тренировках',
          channelDescription: 'Ежедневные напоминания о тренировках',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  Future<void> cancelWorkoutReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWorkoutEnabled, false);
    await _plugin.cancel(_workoutNotificationId);
  }

  // ==================== WATER REMINDERS ====================

  Future<void> scheduleWaterReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWaterEnabled, true);

    // Cancel existing water reminders
    for (int i = 0; i < 8; i++) {
      await _plugin.cancel(_waterBaseNotificationId + i);
    }

    // Schedule reminders every 2 hours from 8:00 to 22:00
    final hours = [8, 10, 12, 14, 16, 18, 20, 22];

    for (int i = 0; i < hours.length; i++) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hours[i], 0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _waterBaseNotificationId + i,
        '💧 Выпей воды!',
        'Не забывай пить воду. Достигни своей цели!',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _waterChannelId,
            'Напоминания о воде',
            channelDescription: 'Напоминания пить воду каждые 2 часа',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    }
  }

  Future<void> cancelWaterReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWaterEnabled, false);
    for (int i = 0; i < 8; i++) {
      await _plugin.cancel(_waterBaseNotificationId + i);
    }
  }

  // ==================== DUEL NOTIFICATIONS ====================

  Future<void> showDuelFinished({
    required String winner,
    required String exerciseType,
  }) async {
    await _plugin.show(
      _duelNotificationId,
      '⚔️ Дуэль завершена!',
      '🏆 Победитель: $winner ($exerciseType)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _duelChannelId,
          'Дуэли',
          channelDescription: 'Уведомления о завершении дуэлей',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ==================== GETTERS ====================

  Future<bool> get isWorkoutEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWorkoutEnabled) ?? false;
  }

  Future<bool> get isWaterEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWaterEnabled) ?? false;
  }

  Future<TimeOfDay> get workoutTime async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyWorkoutHour) ?? 9;
    final minute = prefs.getInt(_keyWorkoutMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
