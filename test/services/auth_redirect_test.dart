import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/config/auth_redirect.dart';

void main() {
  test('Android usa el callback nativo exacto', () {
    expect(
      AuthRedirect.resolve(
        isWeb: false,
        platform: TargetPlatform.android,
        webUri: Uri.parse('http://localhost:3000/'),
      ),
      'transporteinteligente://login-callback/',
    );
  });
  for (final platform in TargetPlatform.values) {
    test('web conserva origin incluso en $platform', () {
      expect(
        AuthRedirect.resolve(
          isWeb: true,
          platform: platform,
          webUri: Uri.parse('https://app.example.test:8443/login?next=home'),
        ),
        'https://app.example.test:8443',
      );
    });
  }
  test('otras plataformas nativas conservan el comportamiento previo', () {
    expect(
      AuthRedirect.resolve(
        isWeb: false,
        platform: TargetPlatform.iOS,
        webUri: Uri.parse('https://app.example.test'),
      ),
      isNull,
    );
  });
}
