import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/duel.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  
  User? _user;
  List<Duel> _duels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getMyProgress();
      final duels = await _apiService.getDuelHistory();
      setState(() {
        _user = user;
        _duels = duels;
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Выйти из аккаунта?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Вы уверены, что хотите выйти?',
          style: TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  int get _totalWins {
    if (_user == null) return 0;
    return _duels.where((d) => d.winner == _user!.username).length;
  }

  int get _totalDuels => _duels.length;

  double get _winRate {
    if (_totalDuels == 0) return 0;
    return (_totalWins / _totalDuels) * 100;
  }

  int get _level {
    if (_user == null) return 1;
    final totalActivity = _user!.pushUps + _user!.squats + (_user!.plankSeconds ~/ 10);
    return (totalActivity / 100).floor() + 1;
  }

  int get _currentLevelXP {
    if (_user == null) return 0;
    final totalActivity = _user!.pushUps + _user!.squats + (_user!.plankSeconds ~/ 10);
    return totalActivity % 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ПРОФИЛЬ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
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
                  children: [
                    // Профиль карточка
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        children: [
                          // Аватар
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00FF88).withOpacity(0.2),
                              border: Border.all(
                                color: const Color(0xFF00FF88),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF00FF88),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Имя пользователя
                          Text(
                            _user?.username ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _user?.email ?? '',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Уровень
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00FF88)),
                            ),
                            child: Text(
                              'УРОВЕНЬ $_level',
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Прогресс уровня
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_currentLevelXP / 100 XP',
                                    style: const TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${(_currentLevelXP / 100 * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _currentLevelXP / 100,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00FF88),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Статистика дуэлей
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Статистика дуэлей',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Всего дуэлей',
                                  _totalDuels.toString(),
                                  Icons.sports_kabaddi,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Побед',
                                  _totalWins.toString(),
                                  Icons.emoji_events,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Процент побед',
                            '${_winRate.toStringAsFixed(1)}%',
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Достижения
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Достижения',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildAchievementBadge(
                                'Новичок',
                                'Первая дуэль',
                                Icons.star,
                                isUnlocked: _totalDuels > 0,
                              ),
                              _buildAchievementBadge(
                                'Боец',
                                '10 дуэлей',
                                Icons.local_fire_department,
                                isUnlocked: _totalDuels >= 10,
                              ),
                              _buildAchievementBadge(
                                'Чемпион',
                                '5 побед',
                                Icons.emoji_events,
                                isUnlocked: _totalWins >= 5,
                              ),
                              _buildAchievementBadge(
                                'Мастер',
                                '100 отжиманий',
                                Icons.fitness_center,
                                isUnlocked: (_user?.pushUps ?? 0) >= 100,
                              ),
                              _buildAchievementBadge(
                                'Атлет',
                                '100 приседаний',
                                Icons.accessibility_new,
                                isUnlocked: (_user?.squats ?? 0) >= 100,
                              ),
                              _buildAchievementBadge(
                                'Железный',
                                '5 мин планки',
                                Icons.timer,
                                isUnlocked: (_user?.plankSeconds ?? 0) >= 300,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00FF88), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, String description, IconData icon, {required bool isUnlocked}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? const Color(0xFF00FF88).withOpacity(0.1)
            : const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF00FF88) : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isUnlocked ? const Color(0xFF00FF88) : const Color(0xFF444444),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUnlocked ? const Color(0xFF00FF88) : const Color(0xFF444444),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUnlocked ? const Color(0xFF888888) : const Color(0xFF444444),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}


