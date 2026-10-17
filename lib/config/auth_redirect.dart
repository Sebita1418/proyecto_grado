import 'package:flutter/foundation.dart';

/// Redirect selection only; Supabase Flutter owns callback exchange/storage.
class AuthRedirect {
  static const androidCallback = 'transporteinteligente://login-callback/';

  static String? current() =>
      resolve(isWeb: kIsWeb, platform: defaultTargetPlatform, webUri: Uri.base);

  static String? resolve({
    required bool isWeb,
    required TargetPlatform platform,
    required Uri webUri,
  }) {
    if (isWeb) return webUri.origin;
    return platform == TargetPlatform.android ? androidCallback : null;
  }
}
