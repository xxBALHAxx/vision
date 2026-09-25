import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'base_exercise.dart';

class _Target {
  final String id;
  final double x, y;
  final double size;
  final String emoji;
  bool hit = false;
  final DateTime spawnedAt;

  _Target({
    required this.id, required this.x, required this.y,
    required this.size, required this.emoji,
  }) : spawnedAt = DateTime.now();
}

class SaccadeExercise extends BaseExercise {
  const SaccadeExercise({super.key, required super.exercise});

  @override
  State<SaccadeExercise> createState() => _SaccadeExerciseState();
}

class _SaccadeExerciseState extends BaseExerciseState<SaccadeExercise> {
  final _rng = Random();
  final List<_Target> _targets = [];
  Timer? _spawnTimer;
  int _hits = 0;
  int _misses = 0;
  int _nextId = 0;

  static const _emojis = ['☄️', '🪨', '💠', '🛸', '⚡', '🌑'];

  @override
  int get maxPossibleScore => 2000;

  @override
  void onExerciseStart() {
    final speed = (widget.exercise.config['speed'] as num?)?.toDouble() ?? 1.0;
    final interval = (800 / speed).round();
    _spawnTimer = Timer.periodic(Duration(milliseconds: interval), (_) => _spawnTarget());
    // Auto-remove stale targets
    Timer.periodic(const Duration(milliseconds: 500), (_) => _pruneTargets());
  }

  @override
  void onExerciseEnd() {
    _spawnTimer?.cancel();
    extraMetrics = {'hits': _hits, 'misses': _misses, 'accuracy': _hits + _misses > 0 ? _hits / (_hits + _misses) : 0};
  }

  void _spawnTarget() {
    if (!mounted) return;
    // Keep max 4 targets on screen
    if (_targets.where((t) => !t.hit).length >= 4) return;

    setState(() {
      _targets.add(_Target(
        id: '${_nextId++}',
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: 0.1 + _rng.nextDouble() * 0.7,
        size: 48 + _rng.nextDouble() * 24,
        emoji: _emojis[_rng.nextInt(_emojis.length)],
      ));
    });
  }

  void _pruneTargets() {
    if (!mounted) return;
    final now = DateTime.now();
    bool changed = false;
    for (final t in _targets) {
      if (!t.hit && now.difference(t.spawnedAt).inMilliseconds > 2500) {
        t.hit = true; // mark expired
        _misses++;
        resetCombo();
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _onHit(_Target target) {
    if (target.hit) return;
    setState(() { target.hit = true; _hits++; });
    addScore(100);
  }

  @override
  Widget buildGameArea() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        children: [
          // Space background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF050A1E), Color(0xFF0A1A3E)],
              ),
            ),
          ),

          // Stars
          CustomPaint(
            size: Size(w, h),
            painter: _BackgroundStarsPainter(),
          ),

          // Stats bar
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(label: '✅ Touchés', value: '$_hits', color: AppTheme.accentGreen),
                  _StatChip(label: '❌ Ratés', value: '$_misses', color: AppTheme.accentRed),
                  _StatChip(
                    label: '🔥 Combo',
                    value: 'x$combo',
                    color: combo > 3 ? AppTheme.accentGold : AppTheme.textSecond,
                  ),
                ],
              ),
            ),
          ),

          // Targets
          ..._targets.map((t) {
            if (t.hit) return const SizedBox.shrink();
            final age = DateTime.now().difference(t.spawnedAt).inMilliseconds;
            final opacity = (1.0 - age / 2500).clamp(0.2, 1.0);

            return Positioned(
              left: t.x * w - t.size / 2,
              top: t.y * h - t.size / 2,
              child: GestureDetector(
                onTap: () => _onHit(t),
                child: Opacity(
                  opacity: opacity,
                  child: _AsteroidWidget(target: t),
                ),
              ),
            );
          }),

          // Hit effects
          ..._targets.where((t) => t.hit).map((t) => Positioned(
            left: t.x * w - 30,
            top: t.y * h - 30,
            child: const _HitEffect(),
          )),
        ],
      );
    });
  }
}

class _AsteroidWidget extends StatefulWidget {
  final _Target target;
  const _AsteroidWidget({required this.target});

  @override
  State<_AsteroidWidget> createState() => _AsteroidWidgetState();
}

class _AsteroidWidgetState extends State<_AsteroidWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      child: Container(
        width: widget.target.size,
        height: widget.target.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentGold.withOpacity(0.15),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: AppTheme.accentGold.withOpacity(0.3), blurRadius: 12),
          ],
        ),
        child: Center(
          child: Text(widget.target.emoji,
              style: TextStyle(fontSize: widget.target.size * 0.45)),
        ),
      ),
    );
  }
}

class _HitEffect extends StatefulWidget {
  const _HitEffect();

  @override
  State<_HitEffect> createState() => _HitEffectState();
}

class _HitEffectState extends State<_HitEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: (1.0 - _ctrl.value).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 1.0 + _ctrl.value * 2,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentGold, width: 2),
            ),
            child: const Center(child: Text('💥', style: TextStyle(fontSize: 24))),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: const TextStyle(color: AppTheme.textSecond, fontSize: 11)),
      ],
    );
  }
}

class _BackgroundStarsPainter extends CustomPainter {
  static final _rng = Random(99);
  static final _stars = List.generate(60, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
  static final _sizes = List.generate(60, (_) => _rng.nextDouble() * 2 + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < _stars.length; i++) {
      canvas.drawCircle(Offset(_stars[i].dx * size.width, _stars[i].dy * size.height), _sizes[i], p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
