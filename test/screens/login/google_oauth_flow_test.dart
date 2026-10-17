import 'dart:convert';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transporte_inteligente/config/auth_redirect.dart';
import 'package:transporte_inteligente/screens/login/login_screen.dart';
import 'package:transporte_inteligente/services/google_auth_service.dart';
import 'package:transporte_inteligente/services/perfil_service.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';

class TestPerfilService extends PerfilService {
  TestPerfilService(this.onLoad);
  final VoidCallback onLoad;
  @override
  Future<Perfil> obtenerOCrearPerfilActual() async {
    onLoad();
    return Perfil(
      id: 'test-user',
      nombre: 'Ana',
      correo: 'test@example.test',
      rol: 'usuario',
      activo: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockClient httpClient;
  var tokenRequests = 0, profileRequests = 0, navigations = 0;
  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://oauth-test.supabase.co',
      publishableKey: 'test-publishable-key',
      httpClient: httpClient,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokenRequests = profileRequests = navigations = 0;
    httpClient = MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        tokenRequests++;
        expect(request.url.queryParameters['grant_type'], 'pkce');
        final body = jsonDecode(request.body) as Map;
        expect(body['auth_code'], 'fake-callback-code');
        expect(body['code_verifier'], isNotEmpty);
        String encode(Object data) =>
            base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
        return http.Response(
          jsonEncode({
            'access_token':
                '${encode({'alg': 'HS256'})}.${encode({'exp': 4102444800, 'sub': 'test-user'})}.test-signature',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'test-user',
              'aud': 'authenticated',
              'email': 'test@example.test',
              'created_at': '2026-10-14T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/rest/v1/perfiles') {
        profileRequests++;
        return http.Response(
          jsonEncode({
            'id': 'test-user',
            'nombre': 'Ana',
            'correo': 'test@example.test',
            'rol': 'usuario',
            'activo': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '{}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    await initialize();
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await Supabase.instance.dispose();
    httpClient.close();
  });
  Future<void> mount(WidgetTester tester, GoogleAuthService service) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          googleAuthService: service,
          perfilService: TestPerfilService(() => profileRequests++),
          authenticatedBuilder: (_) {
            navigations++;
            return const Scaffold(body: Text('Sesión validada'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.ensureVisible(find.text('Continuar con Google'));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('abrir navegador propaga Android y no autentica ni navega', (
    tester,
  ) async {
    String? received;
    await mount(
      tester,
      GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async {
          received = redirectTo;
          return true;
        },
      ),
    );
    await press(tester);
    expect(received, AuthRedirect.androidCallback);
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(profileRequests, 0);
    expect(navigations, 0);
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final outcome in ['false', 'exception']) {
    testWidgets(
      'error de lanzamiento $outcome mantiene login y permite reintentar',
      (tester) async {
        await mount(
          tester,
          GoogleAuthService(
            oauthSignIn: ({String? redirectTo}) async {
              if (outcome == 'exception') {
                throw const AuthException('OAuth failed');
              }
              return false;
            },
          ),
        );
        await press(tester);
        expect(find.textContaining('No fue posible'), findsOneWidget);
        expect(navigations, 0);
        expect(Supabase.instance.client.auth.currentSession, isNull);
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Continuar con Google'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'callback PKCE establece sesión, valida perfil y restaura sesión persistida',
    (tester) async {
      final service = GoogleAuthService(
        oauthSignIn: ({String? redirectTo}) async {
          await Supabase.instance.client.auth.getOAuthSignInUrl(
            provider: OAuthProvider.google,
            redirectTo: redirectTo,
          );
          return true;
        },
      );
      await mount(tester, service);
      await press(tester);
      expect(navigations, 0);
      // Same public SDK entry point called by Supabase Flutter's app_links handler.
      await tester.runAsync(
        () => Supabase.instance.client.auth.getSessionFromUrl(
          Uri.parse('${AuthRedirect.androidCallback}?code=fake-callback-code'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tokenRequests, 1);
      expect(Supabase.instance.client.auth.currentUser!.id, 'test-user');
      expect(profileRequests, 1);
      expect(navigations, 1);
      expect(find.text('Sesión validada'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('sb-oauth-test-auth-token'), isNotNull);
      await tester.runAsync(() async {
        await Supabase.instance.dispose();
        await initialize();
      });
      await mount(tester, service);
      expect(find.text('Sesión validada'), findsOneWidget);
      expect(navigations, 2);
      expect(tokenRequests, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'error del stream de callback se muestra sin sesión ni navegación',
    (tester) async {
      await mount(
        tester,
        GoogleAuthService(oauthSignIn: ({String? redirectTo}) async => true),
      );
      // Supabase Flutter uses this SDK notification after a failed callback exchange.
      // ignore: invalid_use_of_internal_member
      Supabase.instance.client.auth.notifyException(
        const AuthException('access_denied'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('No fue posible completar'), findsOneWidget);
      expect(navigations, 0);
      expect(Supabase.instance.client.auth.currentSession, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
