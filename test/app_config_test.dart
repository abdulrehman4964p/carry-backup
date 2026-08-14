import 'package:flutter_test/flutter_test.dart';
import 'package:forexlancer_mobile/core/app_config.dart';

void main() {
  test('Forexlancer URLs use HTTPS', () {
    expect(Uri.parse(AppConfig.baseUrl).scheme, 'https');
    expect(AppConfig.allowedHosts, contains('forexlancer.com'));
  });
}
