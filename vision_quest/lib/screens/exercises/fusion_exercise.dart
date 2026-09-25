import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'base_exercise.dart';

class FusionExercise extends BaseExercise {
  const FusionExercise({super.key, required super.exercise});

  @override
  State<FusionExercise> createState() => _FusionExerciseState();
}

class _FusionExerciseState extends BaseExerciseState<FusionExercise> {
  late AnimationController _shimmerCtrl;
  bool _fusionActive = false;
  int _fusionStreak = 0;
  int _level = 1;
  static const _maxLevel = 5;

  // Binocular rivalry: left and right images alternate slightly
  static const _leftImages = ['🌍', '🪐', '⭐', '🌙', '☄️'];
  static const _rightImages = ['🌎', '🪐', '⭐', '🌛', '☄️'];
  // Hidden 3D object to "reveal"
  static const _hiddenObjects = ['🚀', '🛸', '👾', '🌟', '💎'];

  @override
  int get maxPossibleScore => 2000;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  void onExerciseStart() {
    Future.delayed(const Duration(seconds: 1), _grantFusionScore);
  }

  void _grantFusionScore() {
    if (!mounted) return;
    if (_fusionActive) {
      _fusionStreak++;
      addScore(60);
      if (_fusionStreak > 0 && _fusionStreak % 5 == 0 && _level < _maxLevel) {
        setState(() => _level++);
      }
    } else {
      _fusionStreak = 0;
    }
    Future.delayed(const Duration(seconds: 1), _grantFusionScore);
  }

  String get _leftImg => _leftImages[(_level - 1).clamp(0, _leftImages.length - 1)];
  String get _rightImg => _rightImages[(_level - 1).clamp(0, _rightImages.length - 1)];
  String get _hiddenObj => _hiddenObjects[(_level - 1).clamp(0, _hiddenObjects.length - 1)];

  @override
  Widget buildGameArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentPurple.withOpacity(0.4)),
            ),
            child: Text(
              'Niveau de fusion : $_level / $_maxLevel',
              style: const TextStyle(
                color: AppTheme.accentPurple,
                fontWeight: FontWeight.w700, fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Binocular images side by side
          Row(
            children: [
              Expanded(child: _EyePanel(label: 'Œil Gauche', emoji: _leftImg, color: AppTheme.accentRed)),
              const SizedBox(width: 12),
              Expanded(child: _EyePanel(label: 'Œil Droit', emoji: _rightImg, color: AppTheme.accentGreen)),
            ],
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '💡 Détends ton regard comme si tu regardais au loin. Les deux images vont se superposer et révéler un objet caché !',
              style: TextStyle(color: AppTheme.textSecond, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Fusion zone - the "merged" view
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) => GestureDetector(
              onTap: () => setState(() => _fusionActive = !_fusionActive),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _fusionActive
                        ? AppTheme.accentPurple
                        : AppTheme.bgSurface,
                    width: 2,
                  ),
                  gradient: LinearGradient(
                    colors: _fusionActive
                        ? [
                            AppTheme.accentPurple.withOpacity(0.2 + _shimmerCtrl.value * 0.1),
                            AppTheme.accentCyan.withOpacity(0.1),
                          ]
                        : [AppTheme.bgCard, AppTheme.bgCard],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _fusionActive ? 1.0 : 0.1,
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        _hiddenObj,
                        style: TextStyle(
                          fontSize: _fusionActive ? 64 : 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fusionActive ? '✨ FUSION ACTIVE !' : '👁 Zone de fusion',
                      style: TextStyle(
                        color: _fusionActive ? AppTheme.accentPurple : AppTheme.textSecond,
                        fontWeight: FontWeight.w700, fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tap button
          GestureDetector(
            onTap: () => setState(() => _fusionActive = !_fusionActive),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _fusionActive
                      ? [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.7)]
                      : [AppTheme.bgSurface, AppTheme.bgSurface],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _fusionActive ? AppTheme.accentPurple : AppTheme.textSecond.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  _fusionActive ? '✅ Je vois l\'objet fusionné !' : '🌀 J\'active la fusion !',
                  style: TextStyle(
                    color: _fusionActive ? AppTheme.bgDeep : AppTheme.textSecond,
                    fontWeight: FontWeight.w800, fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Streak display
          if (_fusionStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🔥 Fusion maintenue : ${_fusionStreak}s',
                style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _EyePanel extends StatelessWidget {
  final String label, emoji;
  final Color color;
  const _EyePanel({required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
