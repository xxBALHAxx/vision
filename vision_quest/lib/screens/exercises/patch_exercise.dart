import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'base_exercise.dart';

class PatchExercise extends BaseExercise {
  const PatchExercise({super.key, required super.exercise});

  @override
  State<PatchExercise> createState() => _PatchExerciseState();
}

class _PatchExerciseState extends BaseExerciseState<PatchExercise> {
  int _currentPuzzle = 0;
  int _solved = 0;
  String? _selectedAnswer;
  bool _correct = false;

  // Simple shape-matching puzzles for the weaker eye
  static const _puzzles = [
    {'shape': '⭐', 'question': 'Combien d\'étoiles ?', 'display': '⭐⭐⭐', 'answer': '3', 'options': ['2', '3', '4', '5']},
    {'shape': '🔴', 'question': 'Quelle couleur ?', 'display': '🔴', 'answer': 'Rouge', 'options': ['Bleu', 'Rouge', 'Vert', 'Jaune']},
    {'shape': '△', 'question': 'Quelle forme ?', 'display': '▲', 'answer': 'Triangle', 'options': ['Carré', 'Cercle', 'Triangle', 'Étoile']},
    {'shape': '2️⃣', 'question': 'Quel chiffre ?', 'display': '7', 'answer': '7', 'options': ['4', '7', '9', '1']},
    {'shape': '🟦', 'question': 'Combien de carrés ?', 'display': '🟦🟦', 'answer': '2', 'options': ['1', '2', '3', '4']},
    {'shape': '🌙', 'question': 'Quelle est cette forme ?', 'display': '🌙', 'answer': 'Lune', 'options': ['Soleil', 'Étoile', 'Lune', 'Planète']},
  ];

  @override
  int get maxPossibleScore => 1500;

  Map<String, dynamic> get _puzzle => _puzzles[_currentPuzzle % _puzzles.length];

  void _onAnswer(String answer) {
    if (_selectedAnswer != null) return;
    final isCorrect = answer == _puzzle['answer'];
    setState(() {
      _selectedAnswer = answer;
      _correct = isCorrect;
    });
    if (isCorrect) { _solved++; addScore(200); }
    else resetCombo();
    Future.delayed(const Duration(milliseconds: 1200), _nextPuzzle);
  }

  void _nextPuzzle() {
    if (!mounted) return;
    setState(() {
      _currentPuzzle++;
      _selectedAnswer = null;
      _correct = false;
    });
  }

  @override
  Widget buildGameArea() {
    final patchedEye = widget.exercise.config['patchedEye'] ?? 'right';
    final patchLabel = patchedEye == 'right' ? '👁️ Œil droit masqué' : '👁️ Œil gauche masqué';

    return Column(
      children: [
        // Patch reminder banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: AppTheme.accentRed.withOpacity(0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🩹', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                patchLabel,
                style: const TextStyle(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w700, fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress
                Text(
                  'Puzzle ${(_currentPuzzle % _puzzles.length) + 1} / ${_puzzles.length}',
                  style: const TextStyle(color: AppTheme.textSecond, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentPuzzle % _puzzles.length) / _puzzles.length,
                    minHeight: 6,
                    backgroundColor: AppTheme.bgSurface,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentRed),
                  ),
                ),

                const SizedBox(height: 32),

                // Display area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.accentRed.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _puzzle['display']!,
                        style: const TextStyle(fontSize: 64),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _puzzle['question']!,
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Answer options
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: (_puzzle['options'] as List<String>).map((opt) {
                    Color btnColor = AppTheme.bgSurface;
                    Color textColor = AppTheme.textPrimary;
                    if (_selectedAnswer == opt) {
                      btnColor = _correct ? AppTheme.accentGreen : AppTheme.accentRed;
                      textColor = AppTheme.bgDeep;
                    } else if (_selectedAnswer != null && opt == _puzzle['answer']) {
                      btnColor = AppTheme.accentGreen.withOpacity(0.3);
                    }
                    return GestureDetector(
                      onTap: () => _onAnswer(opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: btnColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedAnswer == opt
                                ? (_correct ? AppTheme.accentGreen : AppTheme.accentRed)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700, fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Solved counter
                Text(
                  '✅ Résolus : $_solved',
                  style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
