import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget Test: Kartu Info Kendaraan', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Card(child: Text('Motor: 10'))));
    expect(find.text('Motor: 10'), findsOneWidget);
  });
}