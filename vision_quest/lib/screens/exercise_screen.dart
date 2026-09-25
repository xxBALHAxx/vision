import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
import 'exercises/stereogram_exercise.dart';
import 'exercises/convergence_exercise.dart';
import 'exercises/saccade_exercise.dart';
import 'exercises/pursuit_exercise.dart';
import 'exercises/patch_exercise.dart';
import 'exercises/fusion_exercise.dart';

class ExerciseScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseScreen({super.key, required this.exercise});

  Color _typeColor() {
    switch (exercise.type) {
      case ExerciseType.stereogram: return AppTheme.accentCyan;
      case ExerciseType.convergence: return AppTheme.accentGreen;
      case ExerciseType.saccade: return AppTheme.accentGold;
      case ExerciseType.smoothPursuit: return const Color(0xFF00BFFF);
      case ExerciseType.anisometropia: return AppTheme.accentRed;
      case ExerciseType.fusion: return AppTheme.accentPurple;
    }
  }

  void _startExercise(BuildContext context) {
    Widget screen;
    switch (exercise.type) {
      case ExerciseType.stereogram:
        screen = StereogramExercise(exercise: exercise);
        break;
      case ExerciseType.convergence:
        screen = ConvergenceExercise(exercise: exercise);
        break;
      case ExerciseType.saccade:
        screen = SaccadeExercise(exercise: exercise);
        break;
      case ExerciseType.smoothPursuit:
        screen = PursuitExercise(exercise: exercise);
        break;
      case ExerciseType.anisometropia:
        screen = PatchExercise(exercise: exercise);
        break;
      case ExerciseType.fusion:
        screen = FusionExercise(exercise: exercise);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textPrimary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji hero
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.1),
                          border: Border.all(color: color.withOpacity(0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 30, spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(exercise.emoji,
                              style: const TextStyle(fontSize: 52)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        exercise.title,
                        style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),
                      Text(
                        exercise.description,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textSecond),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Info chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InfoChip(label: '⏱ ${exercise.durationSeconds}s', color: color),
                          const SizedBox(width: 10),
                          _InfoChip(
                            label: exercise.difficulty == Difficulty.easy
                                ? '⭐ Facile'
                                : exercise.difficulty == Difficulty.medium
                                    ? '⭐⭐ Moyen'
                                    : '⭐⭐⭐ Difficile',
                            color: color,
                          ),
                          const SizedBox(width: 10),
                          const _InfoChip(label: '⚡ -1', color: AppTheme.accentGold),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Instructions box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, color: color, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Comment jouer',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              exercise.instructions,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Start button
              Padding(
                padding: const EdgeInsets.all(24),
                child: NeonButton(
                  label: 'Commencer ! 🎮',
                  onTap: () => _startExercise(context),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
