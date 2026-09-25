import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'base_exercise.dart';

class PursuitExercise extends BaseExercise {
  const PursuitExercise({super.key, required super.exercise});

  @override
  State<PursuitExercise> createState() => _PursuitExerciseState();
}

class _PursuitExerciseState extends BaseExerciseState<PursuitExercise> {
  late AnimationController _orbitCtrl;
  double _touchX = 0.5;
  double _touchY = 0.5;
  bool _tracking = false;
  static const _hitRadius = 0.12; // fraction of screen width

  @override
  int get maxPossibleScore => 1800;

  double get _speed =>
      (widget.exercise.config['speed'] as num?)?.toDouble() ?? 0.8;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (5000 / _speed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  void onExerciseStart() {
    // Grant continuous score while tracking
    Future.delayed(const Duration(milliseconds: 500), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_tracking) {
      addScore(20);
    }
    Future.delayed(const Duration(milliseconds: 500), _tick);
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    setState(() {
      _touchX = (d.globalPosition.dx / size.width).clamp(0.0, 1.0);
      _touchY = (d.globalPosition.dy / size.height).clamp(0.0, 1.0);
    });
    _checkTracking(size);
  }

  void _checkTracking(Size size) {
    final shipPos = _getShipPosition(size);
    final dx = (_touchX * size.width) - shipPos.dx;
    final dy = (_touchY * size.height) - shipPos.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final threshold = _hitRadius * size.width;
    setState(() => _tracking = dist < threshold);
    if (_tracking) addScore(5);
  }

  Offset _getShipPosition(Size size) {
    final t = _orbitCtrl.value * 2 * pi;
    final cx = size.width / 2;
    final cy = size.height * 0.4;
    final rx = size.width * 0.32;
    final ry = size.height * 0.22;
    return Offset(cx + rx * cos(t), cy + ry * sin(t));
  }

  @override
  Widget buildGameArea() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanUpdate: (d) => _onPanUpdate(d, size),
        onPanStart: (d) {
          _touchX = d.globalPosition.dx / size.width;
          _touchY = d.globalPosition.dy / size.height;
          _checkTracking(size);
        },
        child: AnimatedBuilder(
          animation: _orbitCtrl,
          builder: (_, __) {
            final shipPos = _getShipPosition(size);
            return Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [Color(0xFF0A1540), Color(0xFF050A1E)],
                    ),
                  ),
                ),

                // Orbit path
                CustomPaint(
                  size: size,
                  painter: _OrbitPainter(
                    cx: size.width / 2,
                    cy: size.height * 0.4,
                    rx: size.width * 0.32,
                    ry: size.height * 0.22,
                  ),
                ),

                // Planet at center
                Positioned(
                  left: size.width / 2 - 30,
                  top: size.height * 0.4 - 30,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF4488FF), Color(0xFF1144AA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4488FF).withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(child: Text('🌍', style: TextStyle(fontSize: 28))),
                  ),
                ),

                // Ship
                Positioned(
                  left: shipPos.dx - 24,
                  top: shipPos.dy - 24,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_tracking ? AppTheme.accentGreen : AppTheme.accentCyan)
                              .withOpacity(0.6),
                          blurRadius: _tracking ? 24 : 12,
                          spreadRadius: _tracking ? 4 : 0,
                        ),
                      ],
                    ),
                    child: const Center(child: Text('🚀', style: TextStyle(fontSize: 30))),
                  ),
                ),

                // Finger tracker
                Positioned(
                  left: _touchX * size.width - 20,
                  top: _touchY * size.height - 20,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _tracking ? AppTheme.accentGreen : Colors.white30,
                        width: 2,
                      ),
                      color: (_tracking ? AppTheme.accentGreen : Colors.white)
                          .withOpacity(0.1),
                    ),
                    child: _tracking
                        ? const Center(child: Icon(Icons.check, color: Colors.white, size: 16))
                        : null,
                  ),
                ),

                // Instructions
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _tracking ? Icons.visibility : Icons.visibility_off_outlined,
                          color: _tracking ? AppTheme.accentGreen : AppTheme.textSecond,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _tracking
                              ? '✅ Parfait ! Continue de suivre !'
                              : '🚀 Garde le doigt sur le vaisseau',
                          style: TextStyle(
                            color: _tracking ? AppTheme.accentGreen : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

class _OrbitPainter extends CustomPainter {
  final double cx, cy, rx, ry;
  _OrbitPainter({required this.cx, required this.cy, required this.rx, required this.ry});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentCyan.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
