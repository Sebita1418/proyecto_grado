import 'package:supabase_flutter/supabase_flutter.dart';

typedef GoogleOAuthSignIn = Future<bool> Function({String? redirectTo});

class GoogleAuthException implements Exception {
  const GoogleAuthException({required this.message, required this.cause});

  final String message;
  final Object cause;

  @override
  String toString() => '$message Cause: $cause';
}

class GoogleAuthService {
  GoogleAuthService({GoogleOAuthSignIn? oauthSignIn})
    : _oauthSignIn = oauthSignIn ?? _defaultOAuthSignIn;

  final GoogleOAuthSignIn _oauthSignIn;

  static Future<bool> _defaultOAuthSignIn({String? redirectTo}) {
    return Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  Future<bool> signIn({String? redirectTo}) async {
    try {
      return await _oauthSignIn(redirectTo: redirectTo);
    } catch (error) {
      throw GoogleAuthException(
        message: 'No fue posible iniciar la autenticación con Google.',
        cause: error,
      );
    }
  }
}
