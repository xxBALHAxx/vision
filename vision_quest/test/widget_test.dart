// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vision_quest/main.dart';
import 'package:vision_quest/services/safety_service.dart';
import 'package:vision_quest/services/user_service.dart';

void main() {
  testWidgets('renders the Vision Quest app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserService()),
          ChangeNotifierProvider(create: (_) => SafetyService()),
        ],
        child: const VisionQuestApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
