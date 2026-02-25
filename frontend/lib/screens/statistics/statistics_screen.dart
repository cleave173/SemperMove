import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
      setState(() { _history = history; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('load_error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<ProgressHistory> _getFilteredHistory() {
    if (_history.isEmpty) return [];
    final now = DateTime.now();
    final days = _selectedPeriod == 'week' ? 7 : 30;
    final cutoff = now.subtract(Duration(days: days));
    return _history.where((h) => h.date.isAfter(cutoff)).toList()..sort((a, b) => a.date.compareTo(b.date));
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
                    _buildPeriodSelector(loc, accentColor, isDark, textColor),
                    const SizedBox(height: 24),
                    _buildChartCard(loc.translate('steps'), Icons.directions_walk, _getFilteredHistory(), (h) => h.steps.toDouble(), loc, accentColor, isDark, textColor),
                    const SizedBox(height: 16),
                    _buildChartCard(loc.translate('push_ups'), Icons.accessibility_new, _getFilteredHistory(), (h) => h.pushUps.toDouble(), loc, accentColor, isDark, textColor),
                    const SizedBox(height: 16),
                    _buildChartCard(loc.translate('squats'), Icons.fitness_center, _getFilteredHistory(), (h) => h.squats.toDouble(), loc, accentColor, isDark, textColor),
                    const SizedBox(height: 16),
                    _buildChartCard(loc.translate('plank_sec'), Icons.timer, _getFilteredHistory(), (h) => h.plankSeconds.toDouble(), loc, accentColor, isDark, textColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations loc, Color accent, bool isDark, Color text) {
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
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

  Widget _buildChartCard(String title, IconData icon, List<ProgressHistory> data, double Function(ProgressHistory) getValue, AppLocalizations loc, Color accent, bool isDark, Color text) {
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final gridColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPeriod == 'week' ? loc.translate('last_7_days') : loc.translate('last_30_days'),
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('${data.length} ${loc.days}', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            SizedBox(height: 200, child: Center(child: Text(loc.translate('no_data'), style: const TextStyle(color: Color(0xFF888888)))))
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 30,
                        interval: _selectedPeriod == 'week' ? 1 : 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            final date = data[value.toInt()].date;
                            if (_selectedPeriod == 'week') {
                              final weekdays = [loc.translate('mon'), loc.translate('tue'), loc.translate('wed'), loc.translate('thu'), loc.translate('fri'), loc.translate('sat'), loc.translate('sun')];
                              return Padding(padding: const EdgeInsets.only(top: 8), child: Text(weekdays[date.weekday - 1], style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.bold)));
                            } else {
                              return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${date.day}.${date.month}', style: const TextStyle(color: Color(0xFF888888), fontSize: 9)));
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: Color(0xFF888888), fontSize: 10)))),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0, maxX: (data.length - 1).toDouble(), minY: 0, maxY: _calcMax(data, getValue),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), getValue(e.value))).toList(),
                      isCurved: true, color: accent, barWidth: 3, isStrokeCapRound: true,
                      dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: accent, strokeWidth: 2, strokeColor: cardColor)),
                      belowBarData: BarAreaData(show: true, color: accent.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calcMax(List<ProgressHistory> data, double Function(ProgressHistory) getValue) {
    if (data.isEmpty) return 100;
    return data.map(getValue).reduce((a, b) => a > b ? a : b) * 1.2;
  }
}
