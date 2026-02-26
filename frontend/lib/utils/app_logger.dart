import 'package:flutter/foundation.dart';

/// Централизованный логгер приложения SemperMove.
/// Все логи отображаются в терминале при запуске через `flutter run`.
/// Формат: [ВРЕМЯ] [УРОВЕНЬ] [МОДУЛЬ] Сообщение
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  void info(String module, String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('[$time] [INFO] [$module] $message');
  }

  void warning(String module, String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('[$time] [WARN] [$module] $message');
  }

  void error(String module, String message, [Object? error]) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('[$time] [ERROR] [$module] $message${error != null ? ' | $error' : ''}');
  }

  void action(String module, String action, {Map<String, dynamic>? data}) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final dataStr = data != null ? ' | ${data.entries.map((e) => '${e.key}=${e.value}').join(', ')}' : '';
    debugPrint('[$time] [ACTION] [$module] $action$dataStr');
  }

  void test(String testName, bool passed, {String? details}) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final status = passed ? 'PASS ✓' : 'FAIL ✗';
    debugPrint('[$time] [TEST] [$status] $testName${details != null ? ' | $details' : ''}');
  }
}

final logger = AppLogger();
