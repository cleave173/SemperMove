import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../models/duel.dart';
import '../../l10n/app_localizations.dart';

class DuelDetailScreen extends StatefulWidget {
  final int duelId;
  const DuelDetailScreen({super.key, required this.duelId});

  @override
  State<DuelDetailScreen> createState() => _DuelDetailScreenState();
}

class _DuelDetailScreenState extends State<DuelDetailScreen> {
  final _supabaseService = SupabaseService();
  Duel? _duel;
  bool _isLoading = true;
  bool _isUpdating = false;
  final _challengerScoreC = TextEditingController();
  final _opponentScoreC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDuel();
  }

  @override
  void dispose() {
    _challengerScoreC.dispose();
    _opponentScoreC.dispose();
    super.dispose();
  }

  Future<void> _loadDuel() async {
    setState(() => _isLoading = true);
    try {
      final duel = await _supabaseService.getDuel(widget.duelId);
      setState(() {
        _duel = duel;
        _challengerScoreC.text = duel.challengerScore.toString();
        _opponentScoreC.text = duel.opponentScore.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateScores() async {
    if (_duel == null) return;
    setState(() => _isUpdating = true);
    try {
      await _supabaseService.updateDuelScores(
        widget.duelId,
        int.tryParse(_challengerScoreC.text) ?? 0,
        int.tryParse(_opponentScoreC.text) ?? 0,
      );
      await _loadDuel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).progressUpdated), backgroundColor: Theme.of(context).colorScheme.primary),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _finishDuel() async {
    if (_duel == null) return;
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(loc.translate('finished'), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF888888)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.save, style: TextStyle(color: accentColor))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _supabaseService.finishDuel(widget.duelId);

      // Send push notification
      await NotificationService().showDuelFinished(
        winner: result.winner ?? 'Ничья',
        exerciseType: _getExerciseName(result.exerciseCategory ?? ''),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🏆 ${result.winner ?? ''}'), backgroundColor: Theme.of(context).colorScheme.primary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
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
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(AppLocalizations.of(context).translate('duels_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: textColor), onPressed: _loadDuel)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _duel!.isActive ? accentColor.withOpacity(0.2) : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_duel!.isActive ? Icons.play_circle : Icons.check_circle, color: _duel!.isActive ? accentColor : const Color(0xFF888888)),
                        const SizedBox(width: 8),
                        Text(
                          _duel!.isActive
                              ? AppLocalizations.of(context).translate('in_progress')
                              : AppLocalizations.of(context).translate('finished'),
                          style: TextStyle(color: _duel!.isActive ? accentColor : const Color(0xFF888888), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Participants
                  Row(
                    children: [
                      Expanded(child: _participantCard(_duel!.challengerUsername ?? '?', _duel!.challengerScore, _duel!.winner == _duel!.challengerUsername, cardColor, borderColor, textColor, accentColor)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('VS', style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.bold))),
                      Expanded(child: _participantCard(_duel!.opponentUsername ?? '?', _duel!.opponentScore, _duel!.winner == _duel!.opponentUsername, cardColor, borderColor, textColor, accentColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Exercise
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: Row(children: [
                      Icon(Icons.fitness_center, color: accentColor),
                      const SizedBox(width: 12),
                      Text(_getExerciseName(_duel!.exerciseCategory ?? ''), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),

                  // Update scores (active duels only)
                  if (_duel!.isActive) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: _scoreField(_challengerScoreC, _duel!.challengerUsername ?? '', textColor, cardColor, borderColor, accentColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _scoreField(_opponentScoreC, _duel!.opponentUsername ?? '', textColor, cardColor, borderColor, accentColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateScores,
                        child: _isUpdating
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(AppLocalizations.of(context).save, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _finishDuel,
                        style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(AppLocalizations.of(context).translate('finished'), style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _participantCard(String name, int score, bool isWinner, Color card, Color border, Color text, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWinner ? const Color(0xFFFFD700) : border, width: isWinner ? 2 : 1),
      ),
      child: Column(
        children: [
          if (isWinner) const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 32),
          if (isWinner) const SizedBox(height: 8),
          Text(name, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(score.toString(), style: TextStyle(color: accent, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _scoreField(TextEditingController c, String label, Color text, Color fill, Color border, Color accent) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      style: TextStyle(color: text),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF888888)),
        filled: true, fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
      ),
    );
  }
}
