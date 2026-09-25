import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'base_exercise.dart';

class ConvergenceExercise extends BaseExercise {
  const ConvergenceExercise({super.key, required super.exercise});

  @override
  State<ConvergenceExercise> createState() => _ConvergenceExerciseState();
}

class _ConvergenceExerciseState extends BaseExerciseState<ConvergenceExercise> {
  late AnimationController _moveCtrl;
  // 0.0 = far (top of screen), 1.0 = near (bottom/nose)
  double _progress = 0.0;
  bool _movingIn = true;
  int _cyclesCompleted = 0;
  bool _holding = false;

  @override
  int get maxPossibleScore => 1200;

  @override
  void initState() {
    super.initState();
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    super.dispose();
  }

  @override
  void onExerciseStart() {
    _startCycle();
  }

  void _startCycle() {
    if (!mounted) return;
    _movingIn = true;
    _moveCtrl.reset();
    _moveCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _holding = true);
      // Hold for 2 seconds at near point
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() { _holding = false; _movingIn = false; });
        _moveCtrl.reverse().then((_) {
          if (!mounted) return;
          _cyclesCompleted++;
          addScore(150);
          _startCycle();
        });
      });
    });
  }

  @override
  Widget buildGameArea() {
    return AnimatedBuilder(
      animation: _moveCtrl,
      builder: (context, _) {
        _progress = _movingIn ? _moveCtrl.value : 1.0 - _moveCtrl.value;
        return LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Star position: travels from top-center to bottom-center (near nose)
          final starX = w / 2;
          final starY = 60 + _progress * (h * 0.55);
          final starSize = 20 + _progress * 40; // grows as it approaches

          return Stack(
            children: [
              // Background tunnel effect
              CustomPaint(
                size: Size(w, h),
                painter: _TunnelPainter(progress: _progress),
              ),

              // Label top
              Positioned(
                top: 12,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _holding
                          ? '🔒 Maintiens la netteté !'
                          : _movingIn
                              ? '👀 Suis l\'étoile vers ton nez…'
                              : '↩ Relâche et recule…',
                      style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // The tracking star
              Positioned(
                left: starX - starSize / 2,
                top: starY - starSize / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: starSize,
                  height: starSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        AppTheme.accentGold.withOpacity(0.8),
                        AppTheme.accentGold.withOpacity(0.1),
                      ],
                      stops: const [0.2, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.6 + _progress * 0.4),
                        blurRadius: 20 + _progress * 30,
                        spreadRadius: 2 + _progress * 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '⭐',
                      style: TextStyle(fontSize: starSize * 0.5),
                    ),
                  ),
                ),
              ),

              // Convergence angle guides (two lines from eyes converging on star)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConvergencePainter(
                    starX: starX,
                    starY: starY,
                    w: w, h: h,
                    progress: _progress,
                  ),
                ),
              ),

              // Cycles counter
              Positioned(
                bottom: 20,
                left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔄 Cycles : ', style: TextStyle(color: AppTheme.textSecond)),
                          Text(
                            '$_cyclesCompleted',
                            style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

class _TunnelPainter extends CustomPainter {
  final double progress;
  _TunnelPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final paint = Paint()..style = PaintingStyle.stroke;

    for (int i = 5; i >= 1; i--) {
      final radius = (i / 5) * size.width * 0.45 * (1 - progress * 0.3);
      paint.color = AppTheme.accentCyan.withOpacity(0.05 * i);
      paint.strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_TunnelPainter old) => old.progress != progress;
}

class _ConvergencePainter extends CustomPainter {
  final double starX, starY, w, h, progress;
  _ConvergencePainter({
    required this.starX, required this.starY,
    required this.w, required this.h, required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Left eye guide
    paint.color = AppTheme.accentRed.withOpacity(0.15 + progress * 0.2);
    canvas.drawLine(
      Offset(w * 0.35, h * 0.85),
      Offset(starX, starY),
      paint,
    );

    // Right eye guide
    paint.color = AppTheme.accentGreen.withOpacity(0.15 + progress * 0.2);
    canvas.drawLine(
      Offset(w * 0.65, h * 0.85),
      Offset(starX, starY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ConvergencePainter old) =>
      old.starY != starY || old.progress != progress;
}
