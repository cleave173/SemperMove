import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class CreateDuelScreen extends StatefulWidget {
  const CreateDuelScreen({super.key});

  @override
  State<CreateDuelScreen> createState() => _CreateDuelScreenState();
}

class _CreateDuelScreenState extends State<CreateDuelScreen> {
  final _apiService = ApiService();
  
  List<User> _users = [];
  User? _selectedOpponent;
  String? _selectedExercise;
  bool _isLoading = true;
  bool _isCreating = false;

  final List<Map<String, dynamic>> _exercises = [
    {'id': 'pushups', 'name': 'Отжимания', 'icon': Icons.accessibility_new},
    {'id': 'squats', 'name': 'Приседания', 'icon': Icons.fitness_center},
    {'id': 'plank', 'name': 'Планка', 'icon': Icons.timer},
    {'id': 'steps', 'name': 'Шаги', 'icon': Icons.directions_walk},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _apiService.getAllUsers();
      setState(() {
        _users = users;
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

  Future<void> _createDuel() async {
    if (_selectedOpponent == null || _selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите оппонента и упражнение'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _apiService.startDuel(_selectedOpponent!.id!, _selectedExercise!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Дуэль создана!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
        Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _isCreating = false);
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
          'СОЗДАТЬ ДУЭЛЬ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
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
                  // Выбор оппонента
                  const Text(
                    'Выберите оппонента',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<User>(
                      value: _selectedOpponent,
                      hint: const Text(
                        'Выберите пользователя',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A1A),
                      underline: Container(),
                      style: const TextStyle(color: Colors.white),
                      items: _users.map((user) {
                        return DropdownMenuItem<User>(
                          value: user,
                          child: Text(user.username),
                        );
                      }).toList(),
                      onChanged: (user) {
                        setState(() => _selectedOpponent = user);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Выбор упражнения
                  const Text(
                    'Выберите упражнение',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...  _exercises.map((exercise) {
                    final isSelected = _selectedExercise == exercise['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedExercise = exercise['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF00FF88).withOpacity(0.1)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF00FF88)
                                : const Color(0xFF2A2A2A),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00FF88)
                                    : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                exercise['icon'],
                                color: isSelected ? Colors.black : const Color(0xFF888888),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              exercise['name'],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF00FF88) : Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00FF88),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // Кнопка создания
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createDuel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF88),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'СОЗДАТЬ ДУЭЛЬ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}



