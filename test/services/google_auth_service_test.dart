import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/services/google_auth_service.dart';
import 'package:transporte_inteligente/config/auth_redirect.dart';

void main() {
  group('GoogleAuthService', () {
    test('returns true when OAuth operation returns true', () async {
      final service = GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async => true,
      );

      final result = await service.signIn();

      expect(result, isTrue);
    });

    test('returns false when OAuth operation returns false', () async {
      final service = GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async => false,
      );

      final result = await service.signIn();

      expect(result, isFalse);
    });

    test('passes redirectTo to OAuth operation', () async {
      String? receivedRedirectTo;

      final service = GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async {
          receivedRedirectTo = redirectTo;
          return true;
        },
      );

      const redirectTo = AuthRedirect.androidCallback;

      await service.signIn(redirectTo: redirectTo);

      expect(receivedRedirectTo, redirectTo);
    });

    test('passes null when redirectTo is not provided', () async {
      String? receivedRedirectTo = 'initial-value';

      final service = GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async {
          receivedRedirectTo = redirectTo;
          return true;
        },
      );

      await service.signIn();

      expect(receivedRedirectTo, isNull);
    });

    test('wraps OAuth errors in GoogleAuthException', () async {
      final originalError = Exception('OAuth failed');

      final service = GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async {
          throw originalError;
        },
      );

      try {
        await service.signIn();
        fail('Expected GoogleAuthException to be thrown.');
      } on GoogleAuthException catch (error) {
        expect(
          error.message,
          'No fue posible iniciar la autenticación con Google.',
        );
        expect(error.cause, same(originalError));
      }
    });
  });
}
