import 'package:flutter_test/flutter_test.dart';

import 'package:evolua_pro/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const EvoluaProApp());
  });
}
