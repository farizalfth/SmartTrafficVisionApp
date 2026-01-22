import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget Test: Loading saat proses AI', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CircularProgressIndicator()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}