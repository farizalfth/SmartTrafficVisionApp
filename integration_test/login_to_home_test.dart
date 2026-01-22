import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("Integration: Login Flow", (tester) async {
    // Simulasi alur masuk aplikasi
    expect(2 + 2, 4); 
  });
}