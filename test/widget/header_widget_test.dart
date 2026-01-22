import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget Test: Menampilkan Judul Aplikasi', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(title: Text('Traffic Vision')))));
    expect(find.text('Traffic Vision'), findsOneWidget);
  });
}