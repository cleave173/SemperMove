import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/progress_history.dart';
import '../../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _supabaseService = SupabaseService();
  List<ProgressHistory> _history = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _supabaseService.getProgressHistory();
      if (mounted) {
        setState(() { _history = history; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ProgressHistory> _getFilteredHistory() {
    if (_history.isEmpty) return [];
    final now = DateTime.now();
    final days = _selectedPeriod == 'week' ? 7 : 30;
    final cutoff = now.subtract(Duration(days: days));
    return _history.where((h) => h.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final user = context.watch<UserProvider>().user;
    final filtered = _getFilteredHistory();
    final days = _selectedPeriod == 'week' ? 7 : 30;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(loc.translate('statistics_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: textColor), onPressed: _loadHistory)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : RefreshIndicator(
              color: accentColor,
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Сводка за сегодня
                    if (user != null) _buildTodayCard(loc, user, accentColor, isDark, cardColor, borderColor, textColor),
                    const SizedBox(height: 20),

                    // Выбор периода
                    _buildPeriodSelector(loc, accentColor, isDark, textColor, cardColor, borderColor),
                    const SizedBox(height: 20),

                    // Карточки статистики за период
                    _buildActivityCard(
                      loc.translate('steps'), Icons.directions_walk, accentColor,
                      _sum(filtered, (h) => h.steps), _avg(filtered, (h) => h.steps, days),
                      user?.stepsGoal ?? 10000, '',
                      isDark, cardColor, borderColor, textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      loc.translate('push_ups'), Icons.accessibility_new, Colors.orangeAccent,
                      _sum(filtered, (h) => h.pushUps), _avg(filtered, (h) => h.pushUps, days),
                      user?.pushUpsGoal ?? 100, loc.translate('times'),
                      isDark, cardColor, borderColor, textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      loc.translate('squats'), Icons.fitness_center, Colors.purpleAccent,
                      _sum(filtered, (h) => h.squats), _avg(filtered, (h) => h.squats, days),
                      user?.squatsGoal ?? 100, loc.translate('times'),
                      isDark, cardColor, borderColor, textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      loc.translate('plank'), Icons.timer, Colors.tealAccent,
                      _sum(filtered, (h) => h.plankSeconds), _avg(filtered, (h) => h.plankSeconds, days),
                      user?.plankGoal ?? 300, loc.translate('sec'),
                      isDark, cardColor, borderColor, textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      loc.translate('water'), Icons.water_drop, Colors.blue.shade300,
                      _sum(filtered, (h) => h.waterMl), _avg(filtered, (h) => h.waterMl, days),
                      user?.waterGoal ?? 2000, loc.translate('ml'),
                      isDark, cardColor, borderColor, textColor,
                    ),
                    const SizedBox(height: 20),

                    // Дни активности
                    _buildDaysInfo(loc, filtered, days, accentColor, isDark, cardColor, borderColor, textColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayCard(AppLocalizations loc, dynamic user, Color accent, bool isDark, Color card, Color border, Color text) {
    final items = [
      {'icon': Icons.directions_walk, 'value': '${user.dailySteps}', 'label': loc.translate('steps'), 'color': accent},
      {'icon': Icons.accessibility_new, 'value': '${user.pushUps}', 'label': loc.translate('push_ups'), 'color': Colors.orangeAccent},
      {'icon': Icons.fitness_center, 'value': '${user.squats}', 'label': loc.translate('squats'), 'color': Colors.purpleAccent},
      {'icon': Icons.timer, 'value': '${user.plankSeconds ~/ 60}:${(user.plankSeconds % 60).toString().padLeft(2, '0')}', 'label': loc.translate('plank'), 'color': Colors.tealAccent},
      {'icon': Icons.water_drop, 'value': '${user.waterMl}', 'label': loc.translate('water'), 'color': Colors.blue.shade300},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.todayActivity, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(item['value'] as String, style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(item['label'] as String, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations loc, Color accent, bool isDark, Color text, Color card, Color border) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Expanded(child: _periodButton(loc.translate('week'), 'week', accent, text)),
          Expanded(child: _periodButton(loc.translate('month'), 'month', accent, text)),
        ],
      ),
    );
  }

  Widget _periodButton(String label, String period, Color accent, Color text) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? accent : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : text, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildActivityCard(
    String title, IconData icon, Color color,
    int total, double avg, int goal, String unit,
    bool isDark, Color card, Color border, Color text,
  ) {
    final progress = goal > 0 ? (avg / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold))),
              // Сумма за период
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$total ${unit.isNotEmpty ? unit : ''}', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${avg.toStringAsFixed(0)} / ${goal} ${unit.isNotEmpty ? unit : ''} ${_selectedPeriod == 'week' ? 'в день' : 'в день'}',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysInfo(AppLocalizations loc, List<ProgressHistory> data, int totalDays, Color accent, bool isDark, Color card, Color border, Color text) {
    final activeDays = data.where((h) => h.steps > 0 || h.pushUps > 0 || h.squats > 0 || h.plankSeconds > 0 || h.waterMl > 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPeriod == 'week' ? loc.translate('last_7_days') : loc.translate('last_30_days'),
                  style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeDays / $totalDays ${loc.days}',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('${(activeDays / totalDays * 100).toStringAsFixed(0)}%', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Helpers
  int _sum(List<ProgressHistory> data, int Function(ProgressHistory) getter) {
    if (data.isEmpty) return 0;
    return data.fold(0, (sum, h) => sum + getter(h));
  }

  double _avg(List<ProgressHistory> data, int Function(ProgressHistory) getter, int totalDays) {
    if (data.isEmpty) return 0;
    return _sum(data, getter) / totalDays;
  }
}
