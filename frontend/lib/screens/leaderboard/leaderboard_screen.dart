import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user.dart';
import '../../l10n/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _supabaseService = SupabaseService();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final users = await _supabaseService.getLeaderboard();
      // Sort by activity score
      users.sort((a, b) => b.activityScore.compareTo(a.activityScore));
      setState(() { _users = users; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: Text(loc.translate('leaderboard_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: textColor), onPressed: _loadLeaderboard),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : RefreshIndicator(
              color: accentColor,
              onRefresh: _loadLeaderboard,
              child: _users.isEmpty
                  ? Center(child: Text(loc.translate('no_data'), style: const TextStyle(color: Color(0xFF888888))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final rank = index + 1;
                        return _buildLeaderboardItem(user, rank, accentColor, isDark, textColor);
                      },
                    ),
            ),
    );
  }

  Widget _buildLeaderboardItem(User user, int rank, Color accentColor, bool isDark, Color textColor) {
    final loc = AppLocalizations.of(context);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    Color? rankColor;
    IconData? rankIcon;
    if (rank == 1) { rankColor = const Color(0xFFFFD700); rankIcon = Icons.emoji_events; }
    else if (rank == 2) { rankColor = const Color(0xFFC0C0C0); rankIcon = Icons.emoji_events; }
    else if (rank == 3) { rankColor = const Color(0xFFCD7F32); rankIcon = Icons.emoji_events; }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rank <= 3 ? (rankColor ?? borderColor) : borderColor, width: rank <= 3 ? 2 : 1),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 28)
                : Text('#$rank', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF888888), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: accentColor.withOpacity(0.2),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? Icon(Icons.person, color: accentColor, size: 22) : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(user.username, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${user.activityScore}', style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(loc.translate('score'), style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
