import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/perfil_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final PerfilService _perfilService =
      PerfilService();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> iniciarSesion() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      mostrarMensaje(
        'Por favor ingresa el correo y la contraseña.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Validar credenciales en Supabase
      final response =
          await Supabase.instance.client.auth
              .signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        mostrarMensaje(
          'No fue posible iniciar sesión.',
        );
        return;
      }

      // 2. Consultar el perfil relacionado
      final perfil =
          await _perfilService
              .obtenerPerfilActual();

      // 3. Verificar si el usuario está activo
      if (!perfil.activo) {
        await Supabase.instance.client.auth
            .signOut();

        if (!mounted) return;

        mostrarMensaje(
          'Tu usuario se encuentra inactivo. '
          'Contacta al administrador.',
        );

        return;
      }

      // 4. Usuario activo → entrar al Home
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HomeScreen(),
        ),
      );
    } on AuthException catch (error) {
      mostrarMensaje(
        obtenerMensajeError(
          error.message,
        ),
      );
    } catch (error) {
      debugPrint(
        'ERROR LOGIN: $error',
      );

      // Si algo falla después de autenticarse,
      // cerramos la sesión para evitar sesiones incompletas.
      await Supabase.instance.client.auth
          .signOut();

      mostrarMensaje(
        'No fue posible validar tu perfil.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String obtenerMensajeError(
    String mensaje,
  ) {
    final mensajeLower =
        mensaje.toLowerCase();

    if (mensajeLower.contains(
      'invalid login credentials',
    )) {
      return 'Correo o contraseña incorrectos.';
    }

    if (mensajeLower.contains(
      'email not confirmed',
    )) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }

    return 'No fue posible iniciar sesión: $mensaje';
  }

  void mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.grey[100],
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),

            child: Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),

              padding:
                  const EdgeInsets.all(28),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha: 0.08,
                    ),

                    blurRadius: 15,

                    offset:
                        const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Icon(
                    Icons
                        .directions_bus,

                    size: 80,

                    color: Colors.blue,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Transporte Inteligente',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 26,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Inicia sesión para continuar',

                    style: TextStyle(
                      fontSize: 15,

                      color:
                          Colors.grey[600],
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  TextField(
                    controller:
                        emailController,

                    enabled:
                        !isLoading,

                    keyboardType:
                        TextInputType
                            .emailAddress,

                    decoration:
                        InputDecoration(
                      labelText:
                          'Correo electrónico',

                      prefixIcon:
                          const Icon(
                        Icons
                            .email_outlined,
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    controller:
                        passwordController,

                    enabled:
                        !isLoading,

                    obscureText:
                        obscurePassword,

                    onSubmitted: (_) {
                      if (!isLoading) {
                        iniciarSesion();
                      }
                    },

                    decoration:
                        InputDecoration(
                      labelText:
                          'Contraseña',

                      prefixIcon:
                          const Icon(
                        Icons
                            .lock_outline,
                      ),

                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons
                                  .visibility_off
                              : Icons
                                  .visibility,
                        ),

                        onPressed:
                            isLoading
                                ? null
                                : () {
                                    setState(
                                      () {
                                        obscurePassword =
                                            !obscurePassword;
                                      },
                                    );
                                  },
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    height: 50,

                    child:
                        ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : iniciarSesion,

                      child:
                          isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'INICIAR SESIÓN',
                                ),
                    ),
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