import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/duel.dart';
import 'create_duel_screen.dart';
import 'duel_detail_screen.dart';

class DuelsScreen extends StatefulWidget {
  const DuelsScreen({super.key});

  @override
  State<DuelsScreen> createState() => _DuelsScreenState();
}

class _DuelsScreenState extends State<DuelsScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  
  List<Duel> _activeDuels = [];
  List<Duel> _historyDuels = [];
  bool _isLoadingActive = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDuels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDuels() async {
    setState(() {
      _isLoadingActive = true;
      _isLoadingHistory = true;
    });

    try {
      final active = await _apiService.getActiveDuels();
      final history = await _apiService.getDuelHistory();
      
      setState(() {
        _activeDuels = active;
        _historyDuels = history.where((d) => d.status == 'FINISHED').toList();
        _isLoadingActive = false;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingActive = false;
        _isLoadingHistory = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ДУЭЛИ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDuels,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF88),
          labelColor: const Color(0xFF00FF88),
          unselectedLabelColor: const Color(0xFF888888),
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'История'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateDuelScreen()),
          );
          if (result == true) {
            _loadDuels();
          }
        },
        backgroundColor: const Color(0xFF00FF88),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'СОЗДАТЬ ДУЭЛЬ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_isLoadingActive) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF88)),
      );
    }

    if (_activeDuels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_kabaddi,
              size: 80,
              color: const Color(0xFF888888).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет активных дуэлей',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00FF88),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadDuels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeDuels.length,
        itemBuilder: (context, index) {
          return _buildDuelCard(_activeDuels[index], isActive: true);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF88)),
      );
    }

    if (_historyDuels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: const Color(0xFF888888).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'История дуэлей пуста',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00FF88),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadDuels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyDuels.length,
        itemBuilder: (context, index) {
          return _buildDuelCard(_historyDuels[index], isActive: false);
        },
      ),
    );
  }

  Widget _buildDuelCard(Duel duel, {required bool isActive}) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DuelDetailScreen(duelId: duel.id),
          ),
        );
        if (result == true) {
          _loadDuels();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF00FF88) : const Color(0xFF2A2A2A),
            width: isActive ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF00FF88).withOpacity(0.2)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'В ПРОЦЕССЕ' : 'ЗАВЕРШЕНО',
                    style: TextStyle(
                      color: isActive ? const Color(0xFF00FF88) : const Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isActive && duel.winner != null)
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        duel.winner!,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Участники
            Row(
              children: [
                Expanded(
                  child: _buildParticipant(
                    duel.challenger.username,
                    duel.isSingleCategory ? duel.challengerScore ?? 0 : duel.totalScores?.challenger ?? 0,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildParticipant(
                    duel.opponent.username,
                    duel.isSingleCategory ? duel.opponentScore ?? 0 : duel.totalScores?.opponent ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Категория упражнения
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Color(0xFF888888), size: 16),
                const SizedBox(width: 8),
                Text(
                  _getExerciseName(duel.exerciseCategory ?? duel.exerciseCategories?.join(', ') ?? ''),
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipant(String name, int score) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getExerciseName(String category) {
    switch (category.toLowerCase()) {
      case 'pushups':
        return 'Отжимания';
      case 'squats':
        return 'Приседания';
      case 'plank':
        return 'Планка';
      case 'steps':
        return 'Шаги';
      default:
        return category;
    }
  }
}


