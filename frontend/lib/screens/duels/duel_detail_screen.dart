import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/duel.dart';

class DuelDetailScreen extends StatefulWidget {
  final int duelId;

  const DuelDetailScreen({super.key, required this.duelId});

  @override
  State<DuelDetailScreen> createState() => _DuelDetailScreenState();
}

class _DuelDetailScreenState extends State<DuelDetailScreen> {
  final _apiService = ApiService();
  
  Duel? _duel;
  bool _isLoading = true;
  bool _isUpdating = false;

  final _challengerScoreController = TextEditingController();
  final _opponentScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDuel();
  }

  @override
  void dispose() {
    _challengerScoreController.dispose();
    _opponentScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadDuel() async {
    setState(() => _isLoading = true);
    try {
      final duel = await _apiService.getDuel(widget.duelId);
      setState(() {
        _duel = duel;
        if (duel.isSingleCategory) {
          _challengerScoreController.text = (duel.challengerScore ?? 0).toString();
          _opponentScoreController.text = (duel.opponentScore ?? 0).toString();
        }
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

  Future<void> _updateScores() async {
    if (_duel == null || !_duel!.isSingleCategory) return;

    final challengerScore = int.tryParse(_challengerScoreController.text) ?? 0;
    final opponentScore = int.tryParse(_opponentScoreController.text) ?? 0;

    setState(() => _isUpdating = true);

    try {
      await _apiService.updateDuelScores(widget.duelId, challengerScore, opponentScore);
      await _loadDuel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Очки обновлены!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _finishDuel() async {
    if (_duel == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Завершить дуэль?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Вы уверены, что хотите завершить дуэль?',
          style: TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Завершить', style: TextStyle(color: Color(0xFF00FF88))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.finishDuel(widget.duelId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Победитель: ${result['winner']}'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ДЕТАЛИ ДУЭЛИ',
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
            onPressed: _loadDuel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Статус
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _duel!.isActive 
                          ? const Color(0xFF00FF88).withOpacity(0.2)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _duel!.isActive ? const Color(0xFF00FF88) : const Color(0xFF2A2A2A),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _duel!.isActive ? Icons.play_circle : Icons.check_circle,
                          color: _duel!.isActive ? const Color(0xFF00FF88) : const Color(0xFF888888),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _duel!.isActive ? 'В ПРОЦЕССЕ' : 'ЗАВЕРШЕНО',
                          style: TextStyle(
                            color: _duel!.isActive ? const Color(0xFF00FF88) : const Color(0xFF888888),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Участники
                  Row(
                    children: [
                      Expanded(
                        child: _buildParticipantCard(
                          _duel!.challenger.username,
                          _duel!.isSingleCategory 
                              ? _duel!.challengerScore ?? 0
                              : _duel!.totalScores?.challenger ?? 0,
                          isWinner: _duel!.winner == _duel!.challenger.username,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildParticipantCard(
                          _duel!.opponent.username,
                          _duel!.isSingleCategory 
                              ? _duel!.opponentScore ?? 0
                              : _duel!.totalScores?.opponent ?? 0,
                          isWinner: _duel!.winner == _duel!.opponent.username,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Информация об упражнении
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Color(0xFF00FF88)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getExerciseName(_duel!.exerciseCategory ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Обновление очков (только для активных дуэлей с одной категорией)
                  if (_duel!.isActive && _duel!.isSingleCategory) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Обновить очки',
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
                          child: TextField(
                            controller: _challengerScoreController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: _duel!.challenger.username,
                              labelStyle: const TextStyle(color: Color(0xFF888888)),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _opponentScoreController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: _duel!.opponent.username,
                              labelStyle: const TextStyle(color: Color(0xFF888888)),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateScores,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ОБНОВИТЬ ОЧКИ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _finishDuel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00FF88)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ЗАВЕРШИТЬ ДУЭЛЬ',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildParticipantCard(String name, int score, {bool isWinner = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? const Color(0xFFFFD700) : const Color(0xFF2A2A2A),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 32),
          if (isWinner) const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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



