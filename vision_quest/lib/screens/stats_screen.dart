import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Consumer<UserService>(
          builder: (ctx, userService, _) {
            final profile = userService.profile;
            if (profile == null) return const SizedBox();
            return SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                        const SizedBox(width: 14),
                        const Text(
                          '📊 Mes Statistiques',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Overview cards
                        Row(
                          children: [
                            Expanded(child: _StatCard(label: 'Score Total', value: '${profile.totalScore}', emoji: '⭐', color: AppTheme.accentGold)),
                            const SizedBox(width: 10),
                            Expanded(child: _StatCard(label: 'Niveau', value: '${profile.level}', emoji: '🏆', color: AppTheme.accentCyan)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _StatCard(label: 'Sessions', value: '${profile.history.length}', emoji: '🎮', color: AppTheme.accentPurple)),
                            const SizedBox(width: 10),
                            Expanded(child: _StatCard(label: 'Minutes/semaine', value: '${userService.weeklyMinutes}', emoji: '⏱', color: AppTheme.accentGreen)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Exercise progress
                        const Text(
                          '🎯 Progression par exercice',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),

                        ...ExerciseCatalogue.all.map((ex) {
                          final stars = userService.bestStars(ex.id);
                          final results = profile.history.where((r) => r.exerciseId == ex.id).toList();
                          final attempts = results.length;
                          final bestScore = attempts > 0
                              ? results.map((r) => r.score).reduce((a, b) => a > b ? a : b)
                              : 0;
                          return _ExerciseProgress(
                            exercise: ex,
                            stars: stars,
                            attempts: attempts,
                            bestScore: bestScore,
                          );
                        }),

                        const SizedBox(height: 24),

                        // Conditions reminder
                        if (profile.conditions.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🏥 Rappel médical',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ces exercices sont un complément aux soins orthoptiques. Consultez régulièrement votre orthoptiste pour un suivi personnalisé.',
                                  style: TextStyle(color: AppTheme.textSecond, fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecond)),
        ],
      ),
    );
  }
}

class _ExerciseProgress extends StatelessWidget {
  final Exercise exercise;
  final int stars, attempts, bestScore;
  const _ExerciseProgress({
    required this.exercise, required this.stars,
    required this.attempts, required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(exercise.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$attempts tentative(s) • Meilleur : $bestScore pts',
                    style: const TextStyle(color: AppTheme.textSecond, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: List.generate(3, (i) => Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.accentGold, size: 18,
            )),
          ),
        ],
      ),
    );
  }
}
