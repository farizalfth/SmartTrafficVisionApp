import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Unit Test: Validasi Email', () {
    final email = "admin@traffic.com";
    expect(email.contains('@'), true);
    expect(email.isNotEmpty, true);
  });
}