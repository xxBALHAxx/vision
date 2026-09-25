import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/user_service.dart';
import 'services/safety_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Full screen immersif
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Initialisation des services
  await NotificationService.init();
  await NotificationService.requestPermission();

  final safetyService = SafetyService();
  await safetyService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()..init()),
        ChangeNotifierProvider.value(value: safetyService),
      ],
      child: const VisionQuestApp(),
    ),
  );
}

class VisionQuestApp extends StatefulWidget {
  const VisionQuestApp({super.key});

  @override
  State<VisionQuestApp> createState() => _VisionQuestAppState();
}

class _VisionQuestAppState extends State<VisionQuestApp> {
  @override
  void initState() {
    super.initState();
    // Écouter les événements SafetyService pour les notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyService>().addListener(_onSafetyChanged);
    });
  }

  bool _warningNotifSent = false;
  bool _timeoutNotifSent = false;
  bool _tooCloseNotifSent = false;

  void _onSafetyChanged() {
    final safety = context.read<SafetyService>();

    // Avertissement précoce → notif
    if (safety.earlyWarning && !_warningNotifSent) {
      _warningNotifSent = true;
      NotificationService.showWarning();
    }

    // Timeout → notif
    if (safety.blockReason == SafetyBlockReason.sessionTimeout && !_timeoutNotifSent) {
      _timeoutNotifSent = true;
      NotificationService.showTimeout();
    }

    // Trop proche → notif
    if (safety.blockReason == SafetyBlockReason.tooClose && !_tooCloseNotifSent) {
      _tooCloseNotifSent = true;
      NotificationService.showTooClose();
    }

    // Reset des flags si session réinitialisée
    if (!safety.isBlocked && !safety.earlyWarning) {
      _warningNotifSent = false;
      _timeoutNotifSent = false;
      _tooCloseNotifSent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
