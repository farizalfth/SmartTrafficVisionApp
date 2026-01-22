import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget Test: Input Lokasi', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TextField(decoration: InputDecoration(hintText: 'Cari Jalan')))));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Cari Jalan'), findsOneWidget);
  });
}