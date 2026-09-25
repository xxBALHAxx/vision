import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'base_exercise.dart';

class StereogramExercise extends BaseExercise {
  const StereogramExercise({super.key, required super.exercise});

  @override
  State<StereogramExercise> createState() => _StereogramExerciseState();
}

class _StereogramExerciseState
  extends BaseExerciseState<StereogramExercise> {
  late AnimationController _pulseCtrl;
  double _separation = 60.0;
  bool _fusionDetected = false;
  int _fusionSeconds = 0;

  @override
  int get maxPossibleScore => 1500;

  @override
  void initState() {
    super.initState();
    _separation = (widget.exercise.config['separation'] as num?)?.toDouble() ?? 60.0;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void onExerciseStart() {
    // Start detecting fusion via periodic score
    Future.delayed(const Duration(seconds: 1), _grantFusionScore);
  }

  void _grantFusionScore() {
    if (!mounted || !_isPlaying()) return;
    if (_fusionDetected) {
      _fusionSeconds++;
      addScore(50);
    }
    Future.delayed(const Duration(seconds: 1), _grantFusionScore);
  }

  bool _isPlaying() => isPlaying;

  bool get isPlaying => mounted;

  void _onFusionToggle(bool v) {
    setState(() => _fusionDetected = v);
    if (!v) resetCombo();
  }

  @override
  Widget buildGameArea() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final cx = w / 2;
      final cy = h * 0.35;

      return GestureDetector(
        onTap: () => _onFusionToggle(!_fusionDetected),
        child: Stack(
          children: [
            // Starfield background
            const _StarfieldBackground(),

            // Instructions text
            Positioned(
              top: h * 0.65,
              left: 20, right: 20,
              child: Column(
                children: [
                  const Text(
                    'FAIS CONVERGER LES ORBES !',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppTheme.textSecond, letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _fusionDetected
                            ? AppTheme.accentGreen.withOpacity(0.5)
                            : AppTheme.accentCyan.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Score :', style: TextStyle(color: AppTheme.textSecond)),
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        // Fusion indicator
                        Row(
                          children: [
                            const Text('❤️ ', style: TextStyle(fontSize: 16)),
                            const Text('❤️ ', style: TextStyle(fontSize: 16)),
                            const Text('❤️', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fusion button
                  GestureDetector(
                    onTap: () => _onFusionToggle(!_fusionDetected),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _fusionDetected
                              ? [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.7)]
                              : [AppTheme.accentCyan, AppTheme.accentCyan.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (_fusionDetected ? AppTheme.accentGreen : AppTheme.accentCyan)
                                .withOpacity(0.5),
                            blurRadius: 20, spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        _fusionDetected ? '✅ Je vois les 3 orbes !' : '👁 Je vois la fusion !',
                        style: const TextStyle(
                          color: AppTheme.bgDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // LEFT orb (red - left eye)
            Positioned(
              left: cx - _separation - 20,
              top: cy - 20,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => _Orb(
                  color: AppTheme.accentRed,
                  size: 40 + _pulseCtrl.value * 5,
                  glow: _fusionDetected,
                ),
              ),
            ),

            // RIGHT orb (green - right eye)
            Positioned(
              left: cx + _separation - 20,
              top: cy - 20,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => _Orb(
                  color: AppTheme.accentGreen,
                  size: 40 + _pulseCtrl.value * 5,
                  glow: _fusionDetected,
                  phase: 1.0,
                  pulseValue: _pulseCtrl.value,
                ),
              ),
            ),

            // CENTER fusion orb (appears when fusion detected)
            if (_fusionDetected)
              Positioned(
                left: cx - 24,
                top: cy - 24,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => _Orb(
                    color: Colors.white,
                    size: 48 + _pulseCtrl.value * 8,
                    glow: true,
                    glowColor: AppTheme.accentCyan,
                  ),
                ),
              ),

            // Laser beams connecting orbs
            Positioned.fill(
              child: CustomPaint(
                painter: _LaserPainter(
                  cx: cx, cy: cy,
                  separation: _separation,
                  fusionDetected: _fusionDetected,
                  animation: _pulseCtrl.value,
                ),
              ),
            ),

            // Fusion timer
            if (_fusionDetected)
              Positioned(
                top: cy - 70,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Fusion maintenue : ${_fusionSeconds}s',
                      style: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Orb widget ────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  final bool glow;
  final Color? glowColor;
  final double phase;
  final double? pulseValue;

  const _Orb({
    required this.color, required this.size,
    this.glow = false, this.glowColor,
    this.phase = 0.0, this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final gc = glowColor ?? color;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.3), Colors.transparent],
          stops: const [0.3, 0.7, 1.0],
        ),
        boxShadow: glow ? [
          BoxShadow(color: gc.withOpacity(0.8), blurRadius: 20, spreadRadius: 5),
          BoxShadow(color: gc.withOpacity(0.4), blurRadius: 40, spreadRadius: 10),
        ] : [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 10),
        ],
      ),
    );
  }
}

// ── Laser beam painter ────────────────────────────────────────────
class _LaserPainter extends CustomPainter {
  final double cx, cy, separation, animation;
  final bool fusionDetected;

  _LaserPainter({
    required this.cx, required this.cy, required this.separation,
    required this.fusionDetected, required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final leftX = cx - separation;
    final rightX = cx + separation;

    // Red laser from left orb
    paint.color = AppTheme.accentRed.withOpacity(0.4 + animation * 0.3);
    paint.shader = LinearGradient(
      colors: [AppTheme.accentRed.withOpacity(0.8), Colors.transparent],
    ).createShader(Rect.fromLTWH(leftX, cy - 100, separation, 200));
    canvas.drawLine(Offset(leftX, cy), Offset(cx, cy), paint);

    // Green laser from right orb
    paint.color = AppTheme.accentGreen.withOpacity(0.4 + animation * 0.3);
    paint.shader = LinearGradient(
      colors: [Colors.transparent, AppTheme.accentGreen.withOpacity(0.8)],
    ).createShader(Rect.fromLTWH(cx, cy - 100, separation, 200));
    canvas.drawLine(Offset(rightX, cy), Offset(cx, cy), paint);

    // Convergence glow at center
    if (fusionDetected) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3 + animation * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(cx, cy), 30 + animation * 15, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_LaserPainter old) =>
      old.fusionDetected != fusionDetected || old.animation != animation;
}

// ── Starfield ─────────────────────────────────────────────────────
class _StarfieldBackground extends StatelessWidget {
  const _StarfieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarsPainter(),
      child: Container(),
    );
  }
}

class _StarsPainter extends CustomPainter {
  static final _rng = Random(42);
  static final _stars = List.generate(
    80,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final _sizes = List.generate(80, (_) => _rng.nextDouble() * 2 + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    for (var i = 0; i < _stars.length; i++) {
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        _sizes[i], paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
