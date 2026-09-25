import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

// ─── Safety event types ───────────────────────────────────────────
enum SafetyBlockReason {
  none,
  sessionTimeout,   // 30 min de jeu atteintes
  tooClose,         // Téléphone trop proche du visage
}

// ─── SafetyService ────────────────────────────────────────────────
/// Service central de sécurité oculaire.
///
/// - Démarre un timer de session dès que [startSession] est appelé.
/// - Écoute le capteur de proximité natif du téléphone.
/// - Expose [blockReason] (ChangeNotifier) pour déclencher l'overlay.
/// - [resetSession] repart de zéro (bouton "Je me repose").
class SafetyService extends ChangeNotifier {
  // ── Config ───────────────────────────────────────────────────────
  static const int sessionLimitMinutes = 30;   // ⏱ Limite session
  static const int warningAtMinutes    = 25;   // ⚠️ Avertissement précoce
  static const int proximityHoldMs     = 1500; // Durée avant blocage (ms)

  // ── State ────────────────────────────────────────────────────────
  SafetyBlockReason _blockReason = SafetyBlockReason.none;
  int _sessionSeconds = 0;
  bool _sessionActive = false;
  bool _warningShown = false;

  // Proximité : on bloque seulement si le capteur est near pendant X ms
  bool _proximityNear = false;
  DateTime? _nearSince;

  Timer? _sessionTimer;
  StreamSubscription<int>? _proximitySub;

  // ── Public getters ────────────────────────────────────────────────
  SafetyBlockReason get blockReason => _blockReason;
  bool get isBlocked => _blockReason != SafetyBlockReason.none;
  int get sessionSeconds => _sessionSeconds;
  int get sessionMinutes => _sessionSeconds ~/ 60;
  bool get earlyWarning => _sessionSeconds >= warningAtMinutes * 60 && !isBlocked;
  double get sessionProgress =>
      (_sessionSeconds / (sessionLimitMinutes * 60)).clamp(0.0, 1.0);

  // ── Init / dispose ────────────────────────────────────────────────
  Future<void> init() async {
    await _initProximitySensor();
  }

  Future<void> _initProximitySensor() async {
    try {
      _proximitySub = ProximitySensor.events.listen((int event) {
        // event == 1 → NEAR, event == 0 → FAR
        _onProximityEvent(event == 1);
      });
    } catch (e) {
      // Le simulateur/certains appareils n'ont pas de capteur → silencieux
      debugPrint('[SafetyService] Proximity sensor unavailable: $e');
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _proximitySub?.cancel();
    super.dispose();
  }

  // ── Session control ───────────────────────────────────────────────

  /// Appelé quand l'enfant lance un exercice.
  void startSession() {
    if (_sessionActive) return;
    _sessionActive = true;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  /// Appelé quand l'enfant revient au menu (pause naturelle).
  void pauseSession() {
    _sessionActive = false;
    _sessionTimer?.cancel();
  }

  /// Remet le compteur à zéro après une vraie pause.
  void resetSession() {
    _sessionSeconds = 0;
    _warningShown = false;
    _blockReason = SafetyBlockReason.none;
    _sessionActive = false;
    _sessionTimer?.cancel();
    notifyListeners();
  }

  // ── Internal: session tick ────────────────────────────────────────
  void _onTick(Timer t) {
    if (!_sessionActive) return;
    _sessionSeconds++;

    // Blocage à 30 min
    if (_sessionSeconds >= sessionLimitMinutes * 60) {
      _triggerBlock(SafetyBlockReason.sessionTimeout);
      return;
    }

    // Avertissement à 25 min (une seule fois)
    if (_sessionSeconds == warningAtMinutes * 60 && !_warningShown) {
      _warningShown = true;
      notifyListeners(); // l'UI lit earlyWarning
    }

    // Notification visuelle toutes les 60s pour l'UI
    if (_sessionSeconds % 60 == 0) notifyListeners();
  }

  // ── Internal: proximity ───────────────────────────────────────────
  void _onProximityEvent(bool near) {
    _proximityNear = near;

    if (near) {
      _nearSince ??= DateTime.now();
      // Vérification différée pour éviter les faux positifs
      Future.delayed(Duration(milliseconds: proximityHoldMs), () {
        if (_proximityNear && !isBlocked) {
          _triggerBlock(SafetyBlockReason.tooClose);
        }
      });
    } else {
      _nearSince = null;
      // Si le blocage était dû à la proximité, on peut débloquer auto
      if (_blockReason == SafetyBlockReason.tooClose) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!_proximityNear) {
            _blockReason = SafetyBlockReason.none;
            notifyListeners();
          }
        });
      }
    }
  }

  // ── Block trigger ─────────────────────────────────────────────────
  void _triggerBlock(SafetyBlockReason reason) {
    if (_blockReason == reason) return;
    _blockReason = reason;
    _sessionActive = false;
    _sessionTimer?.cancel();
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  // ── Utility ───────────────────────────────────────────────────────
  String get formattedSessionTime {
    final m = _sessionSeconds ~/ 60;
    final s = _sessionSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get remainingTime {
    final remaining = (sessionLimitMinutes * 60) - _sessionSeconds;
    if (remaining <= 0) return '00:00';
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
