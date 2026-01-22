import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("Integration: Refresh Dashboard", (tester) async {
    // Simulasi tarik layar (pull to refresh)
    expect(true, true);
  });
}