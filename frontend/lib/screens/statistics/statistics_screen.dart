import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../models/progress_history.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _apiService = ApiService();
  List<ProgressHistory> _history = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week'; // week, month

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _apiService.getProgressHistory();
      setState(() {
        _history = history;
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

  List<ProgressHistory> _getFilteredHistory() {
    if (_history.isEmpty) return [];
    
    final now = DateTime.now();
    final daysToShow = _selectedPeriod == 'week' ? 7 : 30;
    final cutoffDate = now.subtract(Duration(days: daysToShow));
    
    return _history
        .where((h) => h.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'СТАТИСТИКА',
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
            onPressed: _loadHistory,
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
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Переключатель периода
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),

                    // График шагов
                    _buildChartCard(
                      title: 'Шаги',
                      icon: Icons.directions_walk,
                      data: _getFilteredHistory(),
                      getValue: (h) => h.steps.toDouble(),
                    ),
                    const SizedBox(height: 16),

                    // График отжиманий
                    _buildChartCard(
                      title: 'Отжимания',
                      icon: Icons.accessibility_new,
                      data: _getFilteredHistory(),
                      getValue: (h) => h.pushUps.toDouble(),
                    ),
                    const SizedBox(height: 16),

                    // График приседаний
                    _buildChartCard(
                      title: 'Приседания',
                      icon: Icons.fitness_center,
                      data: _getFilteredHistory(),
                      getValue: (h) => h.squats.toDouble(),
                    ),
                    const SizedBox(height: 16),

                    // График планки
                    _buildChartCard(
                      title: 'Планка (сек)',
                      icon: Icons.timer,
                      data: _getFilteredHistory(),
                      getValue: (h) => h.plankSeconds.toDouble(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Неделя', 'week'),
          ),
          Expanded(
            child: _buildPeriodButton('Месяц', 'month'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF88) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required List<ProgressHistory> data,
    required double Function(ProgressHistory) getValue,
  }) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF00FF88), size: 20),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedPeriod == 'week' ? 'Последние 7 дней' : 'Последние 30 дней',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data.length} дней',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (data.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Нет данных за выбранный период',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFF2A2A2A),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _selectedPeriod == 'week' ? 1 : 5, // Неделя: каждый день, Месяц: каждые 5 дней
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            final date = data[value.toInt()].date;
                            // Для недели показываем день недели, для месяца - число
                            if (_selectedPeriod == 'week') {
                              final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                              final weekdayIndex = date.weekday - 1;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  weekdays[weekdayIndex],
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${date.day}.${date.month}',
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: _calculateMaxY(data, getValue),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          getValue(entry.value),
                        );
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF00FF88),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF00FF88),
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF0A0A0A),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00FF88).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<ProgressHistory> data, double Function(ProgressHistory) getValue) {
    if (data.isEmpty) return 100;
    
    final maxValue = data.map(getValue).reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2; // добавляем 20% сверху для красоты
  }
}



