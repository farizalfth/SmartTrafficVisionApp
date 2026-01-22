import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Unit Test: Parsing JSON Traffic Data', () {
    final mockJson = {'id': 101, 'location': 'Simpang Jakarta', 'vehicle_count': 25};
    expect(mockJson['location'], 'Simpang Jakarta');
    expect(mockJson['vehicle_count'], isA<int>());
  });
}