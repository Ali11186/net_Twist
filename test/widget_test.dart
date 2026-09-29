import 'package:flutter_test/flutter_test.dart';
import 'package:net_twist/main.dart';

void main() {
  testWidgets('net_Twist login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NetTwistApp());

    expect(find.text('net_Twist'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('إرسال كود التحقق'), findsOneWidget);
  });
}
