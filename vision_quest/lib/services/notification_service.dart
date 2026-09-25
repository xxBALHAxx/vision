import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère les notifications locales de sécurité oculaire.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'vision_quest_safety';
  static const _channelName = 'Sécurité oculaire';
  static const _channelDesc = 'Alertes de temps de jeu et de proximité';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[NotificationService] Permission: $e');
    }
  }

  static Future<void> showWarning() => _show(
        id: 1,
        title: '⚠️ Encore 5 minutes !',
        body: 'Tu joues depuis 25 minutes. Prépare-toi à faire une pause 👁️',
        importance: Importance.high,
      );

  static Future<void> showTimeout() => _show(
        id: 2,
        title: '🛑 Temps de pause !',
        body: 'Tu as joué 30 minutes. Tes yeux ont besoin de repos. Reviens dans 10 min !',
        importance: Importance.max,
      );

  static Future<void> showTooClose() => _show(
        id: 3,
        title: '📱 Éloigne le téléphone !',
        body: 'Tu tiens l\'écran trop près de tes yeux. Garde au moins 30 cm de distance !',
        importance: Importance.max,
      );

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    Importance importance = Importance.high,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: importance,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF00E5FF),
        enableLights: true,
        ledColor: const Color(0xFF00E5FF),
        ledOnMs: 500,
        ledOffMs: 500,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );
      await _plugin.show(
        id, title, body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      debugPrint('[NotificationService] Show error: $e');
    }
  }
}
