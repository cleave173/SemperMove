import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import '../statistics/statistics_screen.dart';
import '../duels/duels_screen.dart';
import '../profile/profile_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StatisticsScreen(),
    DuelsScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          selectedItemColor: accentColor,
          unselectedItemColor: const Color(0xFF888888),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: loc.home),
            BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: loc.statistics),
            BottomNavigationBarItem(icon: const Icon(Icons.sports_kabaddi), label: loc.duels),
            BottomNavigationBarItem(icon: const Icon(Icons.leaderboard), label: loc.leaderboard),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: loc.profile),
          ],
        ),
      ),
    );
  }
}
