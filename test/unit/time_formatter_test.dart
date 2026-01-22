import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Unit Test: Format Tanggal Deteksi', () {
    final date = DateTime(2023, 12, 1);
    expect(date.year, 2023);
  });
}