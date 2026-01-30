import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Widget Test for action_button_test.dart
void main() {
  testWidgets('Widget Test: Tombol Deteksi Kamera', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.camera)))));
    expect(find.byIcon(Icons.camera), findsOneWidget);
  });
}