import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/google_auth_service.dart';
import '../../services/perfil_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../theme/mobility_theme.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final PerfilService _perfilService = PerfilService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  StreamSubscription<AuthState>? _authSubscription;

  bool obscurePassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _navegando = false;

  bool get _bloqueado => isLoading || isGoogleLoading;

  @override
  void initState() {
    super.initState();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (data.session == null) {
        return;
      }

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession) {
        await _validarPerfilYNavegar();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        await _validarPerfilYNavegar();
      }
    });
  }

  Future<void> iniciarSesion() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      mostrarMensaje('Por favor ingresa el correo y la contraseña.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        mostrarMensaje('No fue posible iniciar sesión.');
        return;
      }

      await _validarPerfilYNavegar();
    } on AuthException catch (error) {
      mostrarMensaje(obtenerMensajeError(error.message));
    } catch (error) {
      debugPrint('ERROR LOGIN: $error');

      await Supabase.instance.client.auth.signOut();

      mostrarMensaje('No fue posible validar tu perfil.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> iniciarSesionConGoogle() async {
    if (_bloqueado) {
      return;
    }

    setState(() {
      isGoogleLoading = true;
    });

    try {
      final redirectTo = kIsWeb ? Uri.base.origin : null;

      final iniciado = await _googleAuthService.signIn(redirectTo: redirectTo);

      if (!iniciado && mounted) {
        mostrarMensaje('No fue posible abrir el inicio de sesión con Google.');
      }
    } on GoogleAuthException catch (error) {
      debugPrint('ERROR GOOGLE LOGIN: $error');

      mostrarMensaje('No fue posible iniciar sesión con Google.');
    } catch (error) {
      debugPrint('ERROR GOOGLE LOGIN: $error');

      mostrarMensaje('Ocurrió un error al iniciar sesión con Google.');
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _validarPerfilYNavegar() async {
    if (!mounted || _navegando) {
      return;
    }

    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      return;
    }

    _navegando = true;

    try {
      final perfil = await _perfilService.obtenerOCrearPerfilActual();

      if (!perfil.activo) {
        await Supabase.instance.client.auth.signOut();

        _navegando = false;

        if (!mounted) {
          return;
        }

        mostrarMensaje(
          'Tu usuario se encuentra inactivo. '
          'Contacta al administrador.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (error) {
      debugPrint('ERROR VALIDANDO PERFIL: $error');

      await Supabase.instance.client.auth.signOut();

      _navegando = false;

      if (!mounted) {
        return;
      }

      mostrarMensaje(
        'La cuenta fue autenticada, pero no tiene un perfil '
        'válido en Transporte Inteligente.',
      );
    }
  }

  String obtenerMensajeError(String mensaje) {
    final mensajeLower = mensaje.toLowerCase();

    if (mensajeLower.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (mensajeLower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }

    return 'No fue posible iniciar sesión: $mensaje';
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MobilityDesign.pageInset),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 64, color: colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Transporte Inteligente',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    enabled: !_bloqueado,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passwordController,
                    enabled: !_bloqueado,
                    obscureText: obscurePassword,
                    onSubmitted: (_) {
                      if (!_bloqueado) {
                        iniciarSesion();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: obscurePassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _bloqueado
                            ? null
                            : () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    // Let labels grow under accessibility text scaling.
                    child: ElevatedButton(
                      onPressed: _bloqueado ? null : iniciarSesion,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('INICIAR SESIÓN'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GoogleSignInButton(
                    onPressed: iniciarSesionConGoogle,
                    enabled: !_bloqueado,
                    isLoading: isGoogleLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
