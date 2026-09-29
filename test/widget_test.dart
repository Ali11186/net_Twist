import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_twist/screens/login_screen.dart';

void main() {
  testWidgets(
    'net_Twist login screen loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('net_Twist'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('إرسال كود التحقق'), findsOneWidget);
    },
  );
}
