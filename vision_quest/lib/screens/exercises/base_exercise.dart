import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/user_service.dart';
import '../../services/safety_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/safety_overlay.dart';
import '../home_screen.dart';

/// Base de tous les exercices.
/// Gère : countdown → jeu → résultat + SafetyOverlay intégré.
abstract class BaseExercise extends StatefulWidget {
  final Exercise exercise;
  const BaseExercise({super.key, required this.exercise});
}

abstract class BaseExerciseState<T extends BaseExercise> extends State<T>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────
  int _timeLeft = 0;
  bool _isPlaying = false;
  bool _finished = false;
  int _countdown = 3;
  Timer? _timer;

  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  Map<String, dynamic> extraMetrics = {};

  // ── Lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _timeLeft = widget.exercise.durationSeconds;
    _startCountdown();

    // Démarre la session de sécurité
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SafetyService>().startSession();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Pause la session quand on quitte l'exercice
    // (le service garde le compteur, pause seulement)
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        HapticFeedback.mediumImpact();
      } else {
        t.cancel();
        setState(() { _isPlaying = true; _countdown = 0; });
        onExerciseStart();
        _startGameTimer();
      }
    });
  }

  void _startGameTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _endExercise();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _endExercise() {
    onExerciseEnd();
    setState(() { _finished = true; _isPlaying = false; });
    HapticFeedback.heavyImpact();
    _saveResult();
  }

  Future<void> _saveResult() async {
    final stars = _calculateStars();
    final result = ExerciseResult(
      exerciseId: widget.exercise.id,
      completedAt: DateTime.now(),
      score: score,
      stars: stars,
      durationSeconds: widget.exercise.durationSeconds,
      metrics: {'maxCombo': maxCombo, ...extraMetrics},
    );
    await context.read<UserService>().addResult(result);
  }

  int _calculateStars() {
    if (score == 0) return 1;
    final ratio = score / maxPossibleScore;
    if (ratio >= 0.85) return 3;
    if (ratio >= 0.5) return 2;
    return 1;
  }

  // ── Hooks subclasses ──────────────────────────────────────────────
  void onExerciseStart() {}
  void onExerciseEnd() {}
  int get maxPossibleScore => 1000;

  void addScore(int points) {
    combo++;
    if (combo > maxCombo) maxCombo = combo;
    final bonus = (combo > 1) ? (combo * 0.1 * points).round() : 0;
    setState(() => score += points + bonus);
    HapticFeedback.lightImpact();
  }

  void resetCombo() => setState(() => combo = 0);

  Widget buildGameArea();

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SafetyOverlayWrapper(       // ← wrapper de sécurité
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHUD(),
                    Expanded(child: buildGameArea()),
                  ],
                ),

                // Countdown
                if (!_isPlaying && !_finished && _countdown > 0)
                  _CountdownOverlay(count: _countdown),

                // Résultat
                if (_finished)
                  _ResultOverlay(
                    exercise: widget.exercise,
                    score: score,
                    stars: _calculateStars(),
                    maxCombo: maxCombo,
                    onNext: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (r) => false,
                    ),
                    onRetry: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => widget),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return Consumer<SafetyService>(
      builder: (ctx, safety, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, color: AppTheme.textPrimary, size: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Session timer dans le HUD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: safety.earlyWarning
                    ? const Color(0xFFFF8C00).withOpacity(0.2)
                    : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: safety.earlyWarning
                    ? Border.all(color: const Color(0xFFFF8C00).withOpacity(0.6))
                    : null,
              ),
              child: Row(children: [
                Text(
                  safety.earlyWarning ? '⚠️' : '🕐',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  safety.formattedSessionTime,
                  style: TextStyle(
                    color: safety.earlyWarning
                        ? const Color(0xFFFF8C00)
                        : AppTheme.textSecond,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ]),
            ),

            const Spacer(),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w800, fontSize: 14,
                  ),
                ),
              ]),
            ),

            const SizedBox(width: 8),

            // Timer exercice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _timeLeft <= 10 ? AppTheme.accentRed.withOpacity(0.2) : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: _timeLeft <= 10
                    ? Border.all(color: AppTheme.accentRed.withOpacity(0.5))
                    : null,
              ),
              child: Row(children: [
                const Text('⏱', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    color: _timeLeft <= 10 ? AppTheme.accentRed : AppTheme.textPrimary,
                    fontWeight: FontWeight.w800, fontSize: 14,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Countdown overlay ─────────────────────────────────────────────
class _CountdownOverlay extends StatelessWidget {
  final int count;
  const _CountdownOverlay({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 120, fontWeight: FontWeight.w900,
                color: AppTheme.accentCyan,
              ),
            ),
            const Text('Prêt ?', style: TextStyle(fontSize: 22, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Result overlay ────────────────────────────────────────────────
class _ResultOverlay extends StatefulWidget {
  final Exercise exercise;
  final int score, stars, maxCombo;
  final VoidCallback onNext, onRetry;

  const _ResultOverlay({
    required this.exercise, required this.score, required this.stars,
    required this.maxCombo, required this.onNext, required this.onRetry,
  });

  @override
  State<_ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends State<_ResultOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    blurRadius: 40, spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NIVEAU RÉUSSI ! 🎉',
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary, letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < widget.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppTheme.accentGold, size: 44,
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '+${widget.score}',
                    style: const TextStyle(
                      fontSize: 52, fontWeight: FontWeight.w900,
                      color: AppTheme.accentGold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.maxCombo > 1)
                    _BonusLine(label: '+ BONUS COMBO', value: '+${widget.maxCombo * 50}'),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'Niveau Suivant →',
                    onTap: widget.onNext,
                    color: AppTheme.accentGreen,
                  ),
                  const SizedBox(height: 10),
                  OutlineNeonButton(label: '🔄 Réessayer', onTap: widget.onRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BonusLine extends StatelessWidget {
  final String label, value;
  const _BonusLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecond, fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(
            color: AppTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
