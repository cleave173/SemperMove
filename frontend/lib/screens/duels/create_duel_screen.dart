import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user.dart';
import '../../l10n/app_localizations.dart';

class CreateDuelScreen extends StatefulWidget {
  const CreateDuelScreen({super.key});

  @override
  State<CreateDuelScreen> createState() => _CreateDuelScreenState();
}

class _CreateDuelScreenState extends State<CreateDuelScreen> {
  final _supabaseService = SupabaseService();

  List<User> _users = [];
  User? _selectedOpponent;
  String? _selectedExercise;
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _supabaseService.getAllUsers();
      setState(() { _users = users; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('load_error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createDuel() async {
    if (_selectedOpponent == null || _selectedExercise == null || _selectedOpponent!.id == null) return;

    setState(() => _isCreating = true);
    try {
      await _supabaseService.startDuel(_selectedOpponent!.id!, _selectedExercise!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('create_duel')}!'), backgroundColor: Theme.of(context).colorScheme.primary),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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

    final exercises = [
      {'id': 'pushups', 'name': loc.translate('push_ups'), 'icon': Icons.accessibility_new},
      {'id': 'squats', 'name': loc.translate('squats'), 'icon': Icons.fitness_center},
      {'id': 'plank', 'name': loc.translate('plank'), 'icon': Icons.timer},
      {'id': 'steps', 'name': loc.translate('steps'), 'icon': Icons.directions_walk},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(loc.translate('create_duel'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(loc.translate('username'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<User>(
                      value: _selectedOpponent,
                      hint: Text(loc.translate('username'), style: const TextStyle(color: Color(0xFF888888))),
                      isExpanded: true,
                      dropdownColor: cardColor,
                      underline: Container(),
                      style: TextStyle(color: textColor),
                      items: _users.map((u) => DropdownMenuItem<User>(value: u, child: Text(u.username))).toList(),
                      onChanged: (u) => setState(() => _selectedOpponent = u),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ...exercises.map((ex) {
                    final isSelected = _selectedExercise == ex['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedExercise = ex['id'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor.withOpacity(0.1) : cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? accentColor : borderColor, width: isSelected ? 2 : 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: isSelected ? accentColor : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)), borderRadius: BorderRadius.circular(12)),
                              child: Icon(ex['icon'] as IconData, color: isSelected ? Colors.black : const Color(0xFF888888), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Text(ex['name'] as String, style: TextStyle(color: isSelected ? accentColor : textColor, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const Spacer(),
                            if (isSelected) Icon(Icons.check_circle, color: accentColor),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createDuel,
                      child: _isCreating
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(loc.translate('create_duel'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
