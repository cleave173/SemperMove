import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/duel.dart';
import '../models/progress_history.dart';
import 'auth_service.dart';

/// API сервис
/// Backend-пен байланысу үшін барлық HTTP сұраулар
class ApiService {
  // ВАЖНО: Замените на ваш реальный IP адрес или домен
  static const String baseUrl = 'http://localhost:8080/api'; // для Chrome/iOS
  // static const String baseUrl = 'http://10.0.2.2:8080/api'; // для Android эмулятора
  // static const String baseUrl = 'http://YOUR_IP:8080/api'; // для реального устройства
  
  final AuthService _authService = AuthService();

  // Получить заголовки с авторизацией
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> register(String email, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'token': data['token'],
          'user': User.fromJson(data['user']),
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // ==================== PROGRESS ====================

  Future<User> getMyProgress() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/progress'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch progress');
      }
    } catch (e) {
      throw Exception('Progress error: $e');
    }
  }

  Future<User> updateProgress({
    int? dailySteps,
    int? pushUps,
    int? squats,
    int? plankSeconds,
    int? waterMl,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      
      if (dailySteps != null) body['dailySteps'] = dailySteps;
      if (pushUps != null) body['pushUps'] = pushUps;
      if (squats != null) body['squats'] = squats;
      if (plankSeconds != null) body['plankSeconds'] = plankSeconds;
      if (waterMl != null) body['waterMl'] = waterMl;

      final response = await http.post(
        Uri.parse('$baseUrl/progress/update'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update progress');
      }
    } catch (e) {
      throw Exception('Update progress error: $e');
    }
  }

  // ==================== DUELS ====================

  Future<Map<String, dynamic>> startDuel(int opponentId, String exerciseCategory) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/duels/start'),
        headers: headers,
        body: jsonEncode({
          'opponentId': opponentId,
          'exerciseCategory': exerciseCategory,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to start duel');
      }
    } catch (e) {
      throw Exception('Start duel error: $e');
    }
  }

  Future<List<Duel>> getActiveDuels() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/duels/active'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List duels = data['activeDuels'] ?? [];
        return duels.map((json) => Duel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch active duels');
      }
    } catch (e) {
      throw Exception('Active duels error: $e');
    }
  }

  Future<List<Duel>> getDuelHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/duels/history'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List duels = data['duels'] ?? [];
        return duels.map((json) => Duel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch duel history');
      }
    } catch (e) {
      throw Exception('Duel history error: $e');
    }
  }

  Future<Duel> getDuel(int duelId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/duels/$duelId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Duel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch duel');
      }
    } catch (e) {
      throw Exception('Get duel error: $e');
    }
  }

  Future<Map<String, dynamic>> updateDuelScores(int duelId, int challengerScore, int opponentScore) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/duels/$duelId/update-scores'),
        headers: headers,
        body: jsonEncode({
          'challengerScore': challengerScore,
          'opponentScore': opponentScore,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update scores');
      }
    } catch (e) {
      throw Exception('Update scores error: $e');
    }
  }

  Future<Map<String, dynamic>> finishDuel(int duelId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/duels/$duelId/finish'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to finish duel');
      }
    } catch (e) {
      throw Exception('Finish duel error: $e');
    }
  }

  // ==================== HISTORY ====================

  Future<List<ProgressHistory>> getProgressHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => ProgressHistory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch history');
      }
    } catch (e) {
      throw Exception('History error: $e');
    }
  }

  Future<ProgressHistory> addProgressHistory(ProgressHistory history) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/history/add'),
        headers: headers,
        body: jsonEncode(history.toJson()),
      );

      if (response.statusCode == 200) {
        return ProgressHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add history');
      }
    } catch (e) {
      throw Exception('Add history error: $e');
    }
  }

  // ==================== USERS ====================

  Future<List<User>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Get users error: $e');
    }
  }
}

