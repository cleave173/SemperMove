import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/duel.dart';
import '../../l10n/app_localizations.dart';
import 'create_duel_screen.dart';
import 'duel_detail_screen.dart';

class DuelsScreen extends StatefulWidget {
  const DuelsScreen({super.key});

  @override
  State<DuelsScreen> createState() => _DuelsScreenState();
}

class _DuelsScreenState extends State<DuelsScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;

  List<Duel> _activeDuels = [];
  List<Duel> _historyDuels = [];
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    try {
      final active = await _supabaseService.getActiveDuels();
      final history = await _supabaseService.getDuelHistory();

      // Автоматически синхронизируем очки всех активных дуэлей из профилей
      final syncedActive = <Duel>[];
      for (final duel in active) {
        try {
          final synced = await _supabaseService.syncDuelScoresFromProfiles(duel.id);
          syncedActive.add(synced);
        } catch (_) {
          syncedActive.add(duel);
        }
      }

      setState(() {
        _activeDuels = syncedActive;
        _historyDuels = history.where((d) => d.isFinished).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('load_error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getExerciseName(String category) {
    final loc = AppLocalizations.of(context);
    switch (category.toLowerCase()) {
      case 'pushups': return loc.translate('push_ups');
      case 'squats': return loc.translate('squats');
      case 'plank': return loc.translate('plank');
      case 'steps': return loc.translate('steps');
      default: return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(loc.translate('duels_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: textColor), onPressed: _loadDuels)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: const Color(0xFF888888),
          tabs: [Tab(text: loc.translate('active')), Tab(text: loc.translate('history'))],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDuelList(_activeDuels, loc.translate('no_active_duels'), Icons.sports_kabaddi, true),
                _buildDuelList(_historyDuels, loc.translate('no_history'), Icons.history, false),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateDuelScreen()));
          if (result == true) _loadDuels();
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(loc.translate('create_duel'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDuelList(List<Duel> duels, String emptyText, IconData emptyIcon, bool isActive) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (duels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: const Color(0xFF888888).withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(emptyText, style: const TextStyle(color: Color(0xFF888888), fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: _loadDuels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: duels.length,
        itemBuilder: (context, index) {
          final duel = duels[index];
          final loc = AppLocalizations.of(context);
          final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
          final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

          return GestureDetector(
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DuelDetailScreen(duelId: duel.id)),
              );
              if (result == true) _loadDuels();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? accentColor : borderColor, width: isActive ? 2 : 1),
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
                          color: isActive ? accentColor.withOpacity(0.2) : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? loc.translate('in_progress') : loc.translate('finished'),
                          style: TextStyle(color: isActive ? accentColor : const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!isActive && duel.winner != null)
                        Row(children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 4),
                          Text(duel.winner!, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildParticipant(duel.challengerUsername ?? '?', duel.challengerScore, isDark)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('VS', style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: _buildParticipant(duel.opponentUsername ?? '?', duel.opponentScore, isDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.fitness_center, color: Color(0xFF888888), size: 16),
                    const SizedBox(width: 8),
                    Text(_getExerciseName(duel.exerciseCategory ?? ''), style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticipant(String name, int score, bool isDark) {
    return Column(
      children: [
        Text(name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(score.toString(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
