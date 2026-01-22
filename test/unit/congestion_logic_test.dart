import 'package:flutter_test/flutter_test.dart';

String calculateStatus(int count) => count > 20 ? "Macet" : "Lancar";

void main() {
  test('Unit Test: Status Macet jika kendaraan > 20', () {
    expect(calculateStatus(25), "Macet");
    expect(calculateStatus(5), "Lancar");
  });
}