import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/safety_service.dart';
import '../utils/app_theme.dart';

/// Widget wrapper à poser autour de n'importe quel écran.
/// Affiche un overlay bloquant dès que [SafetyService.isBlocked] est true.
///
/// Usage :
/// ```dart
/// SafetyOverlayWrapper(child: HomeScreen())
/// ```
class SafetyOverlayWrapper extends StatelessWidget {
  final Widget child;
  const SafetyOverlayWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetyService>(
      builder: (ctx, safety, _) {
        return Stack(
          children: [
            child,

            // ── Avertissement précoce (bannière non-bloquante) ────
            if (safety.earlyWarning && !safety.isBlocked)
              const Positioned(
                top: 0, left: 0, right: 0,
                child: _WarningBanner(),
              ),

            // ── Overlay bloquant ──────────────────────────────────
            if (safety.isBlocked)
              _BlockOverlay(reason: safety.blockReason),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bannière d'avertissement (25 min)
// ─────────────────────────────────────────────────────────────────
class _WarningBanner extends StatefulWidget {
  const _WarningBanner();

  @override
  State<_WarningBanner> createState() => _WarningBannerState();
}

class _WarningBannerState extends State<_WarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8C00),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C00).withOpacity(0.5),
              blurRadius: 16, spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Plus que 5 minutes !',
                    style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
                    ),
                  ),
                  Text(
                    'Temps restant : ${context.watch<SafetyService>().remainingTime}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

// ─────────────────────────────────────────────────────────────────
// Overlay bloquant
// ─────────────────────────────────────────────────────────────────
class _BlockOverlay extends StatefulWidget {
  final SafetyBlockReason reason;
  const _BlockOverlay({required this.reason});

  @override
  State<_BlockOverlay> createState() => _BlockOverlayState();
}

class _BlockOverlayState extends State<_BlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  // Countdown pour réactiver (timeout uniquement)
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  bool _canUnlock = false;
  static const _cooldownDuration = 600; // 10 minutes en secondes

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.3)),
    );
    _ctrl.forward();

    // Démarre le cooldown pour session timeout
    if (widget.reason == SafetyBlockReason.sessionTimeout) {
      _cooldownSeconds = _cooldownDuration;
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_cooldownSeconds <= 1) {
          t.cancel();
          setState(() => _canUnlock = true);
        } else {
          setState(() => _cooldownSeconds--);
        }
      });
    } else {
      // Pour tooClose, déblocage auto dès que l'enfant s'éloigne
      _canUnlock = false;
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  String get _cooldownDisplay {
    final m = _cooldownSeconds ~/ 60;
    final s = _cooldownSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onResume() {
    if (!_canUnlock) return;
    context.read<SafetyService>().resetSession();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isTimeout = widget.reason == SafetyBlockReason.sessionTimeout;
    final isTooClose = widget.reason == SafetyBlockReason.tooClose;

    // Pour tooClose, écouter si le service a déjà auto-débloqué
    final safety = context.watch<SafetyService>();
    if (isTooClose && !safety.isBlocked) {
      // Auto-déblocage géré par SafetyService → rien à faire, le Consumer parent rebuild
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Center(
            child: Transform.scale(
              scale: _scale.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône animée
                    _PulsingIcon(
                      emoji: isTimeout ? '😴' : '📱',
                      color: isTimeout ? AppTheme.accentGold : AppTheme.accentRed,
                    ),

                    const SizedBox(height: 28),

                    // Titre
                    Text(
                      isTimeout ? 'Temps de pause !' : 'Trop près !',
                      style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isTimeout
                              ? AppTheme.accentGold.withOpacity(0.4)
                              : AppTheme.accentRed.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isTimeout
                                ? 'Tu as joué pendant 30 minutes 🕹️\nTes yeux ont besoin de se reposer !'
                                : 'Le téléphone est trop proche\nde ton visage ! 😰',
                            style: const TextStyle(
                              fontSize: 16, color: AppTheme.textPrimary,
                              height: 1.6, fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Conseil santé
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isTimeout
                                  ? '💡 Règle des 20-20-20 :\nToutes les 20 min, regarde à\n20 mètres pendant 20 secondes.'
                                  : '💡 Distance recommandée :\nTiens le téléphone à au moins\n30-40 cm de tes yeux.',
                              style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecond,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Countdown ou déblocage
                    if (isTimeout) ...[
                      if (!_canUnlock) ...[
                        // Countdown visuel
                        _CountdownRing(
                          secondsLeft: _cooldownSeconds,
                          totalSeconds: _cooldownDuration,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Reviens dans $_cooldownDisplay',
                          style: const TextStyle(
                            color: AppTheme.textSecond, fontSize: 14,
                          ),
                        ),
                      ] else ...[
                        // Bouton de reprise disponible
                        _ResumeButton(onTap: _onResume),
                      ],
                    ],

                    if (isTooClose) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sensors, color: AppTheme.accentRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Le jeu reprend automatiquement\nquand tu t\'éloignes 👍',
                              style: TextStyle(
                                color: AppTheme.accentRed, fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Petits tips de pause
                    if (isTimeout && !_canUnlock) _RestTips(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Icône pulsante
// ─────────────────────────────────────────────────────────────────
class _PulsingIcon extends StatefulWidget {
  final String emoji;
  final Color color;
  const _PulsingIcon({required this.emoji, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.1 + _ctrl.value * 0.1),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3 + _ctrl.value * 0.3),
              blurRadius: 20 + _ctrl.value * 30,
              spreadRadius: 2 + _ctrl.value * 8,
            ),
          ],
        ),
        child: Center(
          child: Text(widget.emoji, style: const TextStyle(fontSize: 56)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Anneau de countdown
// ─────────────────────────────────────────────────────────────────
class _CountdownRing extends StatelessWidget {
  final int secondsLeft, totalSeconds;
  const _CountdownRing({required this.secondsLeft, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final progress = secondsLeft / totalSeconds;
    return SizedBox(
      width: 100, height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: AppTheme.bgSurface,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${secondsLeft ~/ 60}',
                style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: AppTheme.accentCyan,
                ),
              ),
              const Text('min', style: TextStyle(fontSize: 11, color: AppTheme.textSecond)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bouton de reprise
// ─────────────────────────────────────────────────────────────────
class _ResumeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ResumeButton({required this.onTap});

  @override
  State<_ResumeButton> createState() => _ResumeButtonState();
}

class _ResumeButtonState extends State<_ResumeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '✅ Tu peux reprendre !',
          style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGreen, Color(0xFF00CC44)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGreen
                        .withOpacity(0.4 + _ctrl.value * 0.3),
                    blurRadius: 20 + _ctrl.value * 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                '🎮 Je reprends le jeu !',
                style: TextStyle(
                  color: AppTheme.bgDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tips pendant la pause
// ─────────────────────────────────────────────────────────────────
class _RestTips extends StatelessWidget {
  static const _tips = [
    '👀  Regarde par la fenêtre au loin',
    '🚶  Lève-toi et marche un peu',
    '💧  Bois un verre d\'eau',
    '😌  Ferme les yeux 30 secondes',
    '🌿  Regarde quelque chose de vert',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Pendant ta pause :',
          style: TextStyle(color: AppTheme.textSecond, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ..._tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(tip, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        )),
      ],
    );
  }
}
