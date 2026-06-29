import 'package:crop_disease_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService URL handling', () {
    test('normalizes a saved server URL', () {
      expect(
        ApiService.normalizeBaseUrl('  http://localhost:5000/  '),
        'http://localhost:5000',
      );
    });

    test('builds a correct URI for the health endpoint', () {
      ApiService.baseUrl = 'http://localhost:5000/';
      expect(
        ApiService.buildUri('/health').toString(),
        'http://localhost:5000/health',
      );
    });
  });
}
