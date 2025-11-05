import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  
  User? _user;
  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final username = await _authService.getUsername();
      final user = await _apiService.getMyProgress();
      setState(() {
        _username = username;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProgress(String type, int increment) async {
    if (_user == null) return;

    try {
      User updatedUser;
      switch (type) {
        case 'steps':
          updatedUser = await _apiService.updateProgress(
            dailySteps: _user!.dailySteps + increment,
          );
          break;
        case 'pushups':
          updatedUser = await _apiService.updateProgress(
            pushUps: _user!.pushUps + increment,
          );
          break;
        case 'squats':
          updatedUser = await _apiService.updateProgress(
            squats: _user!.squats + increment,
          );
          break;
        case 'plank':
          updatedUser = await _apiService.updateProgress(
            plankSeconds: _user!.plankSeconds + increment,
          );
          break;
        case 'water':
          updatedUser = await _apiService.updateProgress(
            waterMl: _user!.waterMl + increment,
          );
          break;
        default:
          return;
      }

      setState(() => _user = updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Прогресс обновлен!'),
            backgroundColor: Color(0xFF00FF88),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEMPER MOVE',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Привет, ${_username ?? ""}!',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            )
          : RefreshIndicator(
              color: const Color(0xFF00FF88),
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок секции
                    const Text(
                      'Сегодняшняя активность',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Карточки активности
                    _buildActivityCard(
                      title: 'Шаги',
                      value: _user?.dailySteps ?? 0,
                      goal: 10000,
                      unit: '',
                      icon: Icons.directions_walk,
                      onAdd: () => _updateProgress('steps', 100),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActivityCard(
                      title: 'Отжимания',
                      value: _user?.pushUps ?? 0,
                      goal: 100,
                      unit: 'раз',
                      icon: Icons.accessibility_new,
                      onAdd: () => _updateProgress('pushups', 10),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActivityCard(
                      title: 'Приседания',
                      value: _user?.squats ?? 0,
                      goal: 100,
                      unit: 'раз',
                      icon: Icons.fitness_center,
                      onAdd: () => _updateProgress('squats', 10),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActivityCard(
                      title: 'Планка',
                      value: _user?.plankSeconds ?? 0,
                      goal: 300,
                      unit: 'сек',
                      icon: Icons.timer,
                      onAdd: () => _updateProgress('plank', 30),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActivityCard(
                      title: 'Вода',
                      value: _user?.waterMl ?? 0,
                      goal: 2000,
                      unit: 'мл',
                      icon: Icons.local_drink,
                      onAdd: () => _updateProgress('water', 250),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required int value,
    required int goal,
    required String unit,
    required IconData icon,
    required VoidCallback onAdd,
  }) {
    final progress = (value / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF00FF88), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$value / $goal $unit',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: Color(0xFF00FF88)),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% выполнено',
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


