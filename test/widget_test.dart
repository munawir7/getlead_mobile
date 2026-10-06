
import 'package:flutter_test/flutter_test.dart';

import 'package:getlead_mobile/main.dart';

void main() {
  testWidgets('Getlead app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GetleadApp());

    expect(find.text('Welcome to Getlead'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}

