import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import 'exercise_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Consumer<UserService>(
          builder: (context, userService, _) {
            final profile = userService.profile;
            if (profile == null) return const SizedBox();

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _Header(profile: profile, userService: userService),
                  ),

                  // ── Daily Mission ────────────────────────────────
                  SliverToBoxAdapter(
                    child: _DailyMission(userService: userService),
                  ),

                  // ── Exercise grid title ──────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        '🎮 Exercices',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // ── Exercise grid ────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final ex = ExerciseCatalogue.all[i];
                          final stars = userService.bestStars(ex.id);
                          return _ExerciseCard(
                            exercise: ex,
                            stars: stars,
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => ExerciseScreen(exercise: ex),
                              ),
                            ),
                          );
                        },
                        childCount: ExerciseCatalogue.all.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Header widget ─────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final UserProfile profile;
  final UserService userService;
  const _Header({required this.profile, required this.userService});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentCyan, AppTheme.accentPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withOpacity(0.4),
                      blurRadius: 12, spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🧒', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${profile.name} !',
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Niveau ${profile.level} • ${profile.totalScore} pts',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecond),
                    ),
                  ],
                ),
              ),

              // Energy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.energy}/${profile.maxEnergy}',
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Stats button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: AppTheme.accentCyan, size: 22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // XP progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP : ${profile.currentXp} / ${profile.xpForNextLevel}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecond),
                  ),
                  Text(
                    'Prochain niveau →',
                    style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.xpProgress,
                  minHeight: 8,
                  backgroundColor: AppTheme.bgSurface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Daily mission card ────────────────────────────────────────────
class _DailyMission extends StatelessWidget {
  final UserService userService;
  const _DailyMission({required this.userService});

  @override
  Widget build(BuildContext context) {
    final sessions = userService.sessionsToday;
    final goal = 3;
    final done = sessions >= goal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: done
                ? [AppTheme.accentGreen.withOpacity(0.15), AppTheme.bgCard]
                : [AppTheme.accentPurple.withOpacity(0.15), AppTheme.bgCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? AppTheme.accentGreen.withOpacity(0.4) : AppTheme.accentPurple.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Text(done ? '🏆' : '🎯', style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? 'Mission du jour accomplie !' : 'Mission du jour',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done
                        ? 'Super travail ! Reviens demain 💪'
                        : 'Fais $goal exercices aujourd\'hui ($sessions/$goal faits)',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecond),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (sessions / goal).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.bgSurface,
                      valueColor: AlwaysStoppedAnimation(
                        done ? AppTheme.accentGreen : AppTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int stars;
  final VoidCallback onTap;
  const _ExerciseCard({required this.exercise, required this.stars, required this.onTap});

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

  String _typeName() {
    switch (exercise.type) {
      case ExerciseType.stereogram: return 'Stéréogramme';
      case ExerciseType.convergence: return 'Convergence';
      case ExerciseType.saccade: return 'Saccade';
      case ExerciseType.smoothPursuit: return 'Poursuite';
      case ExerciseType.anisometropia: return 'Occlusion';
      case ExerciseType.fusion: return 'Fusion';
    }
  }

  String _diffLabel() {
    switch (exercise.difficulty) {
      case Difficulty.easy: return '⭐ Facile';
      case Difficulty.medium: return '⭐⭐ Moyen';
      case Difficulty.hard: return '⭐⭐⭐ Difficile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12, spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + emoji area
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(exercise.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _typeName(),
                      style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _diffLabel(),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecond),
                  ),
                  const SizedBox(height: 8),
                  // Stars earned
                  Row(
                    children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppTheme.accentGold,
                        size: 16,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
