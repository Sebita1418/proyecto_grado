import 'package:flutter/material.dart';

import '../../../models/perfil_model.dart';
import '../../../services/perfil_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() =>
      _UsuariosScreenState();
}

class _UsuariosScreenState
    extends State<UsuariosScreen> {
  final PerfilService _perfilService =
      PerfilService();

  bool cargando = true;
  String? error;

  List<Perfil> usuarios = [];

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    try {
      final resultado =
          await _perfilService.obtenerPerfiles();

      if (!mounted) return;

      setState(() {
        usuarios = resultado;
        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        cargando = false;
      });
    }
  }

  Future<void> abrirFormularioUsuario() async {
    final nombreController =
        TextEditingController();

    final correoController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    String rolSeleccionado = 'usuario';
    bool ocultarPassword = true;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool procesando = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Nuevo usuario',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      TextField(
                        controller:
                            nombreController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nombre completo',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            correoController,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Correo electrónico',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            passwordController,
                        obscureText:
                            ocultarPassword,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Contraseña',
                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setDialogState(() {
                                ocultarPassword =
                                    !ocultarPassword;
                              });
                            },
                            icon: Icon(
                              ocultarPassword
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            rolSeleccionado,
                        decoration:
                            const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(
                            Icons
                                .admin_panel_settings_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'usuario',
                            child:
                                Text('Usuario'),
                          ),
                          DropdownMenuItem(
                            value:
                                'administrador',
                            child: Text(
                              'Administrador',
                            ),
                          ),
                        ],
                        onChanged: (valor) {
                          if (valor != null) {
                            rolSeleccionado =
                                valor;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: procesando
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },
                  child:
                      const Text('Cancelar'),
                ),

                ElevatedButton(
                  onPressed: procesando
                      ? null
                      : () async {
                          final nombre =
                              nombreController
                                  .text
                                  .trim();

                          final correo =
                              correoController
                                  .text
                                  .trim();

                          final password =
                              passwordController
                                  .text;

                          if (nombre.isEmpty ||
                              correo.isEmpty ||
                              password.isEmpty) {
                            ScaffoldMessenger
                                    .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Completa todos los campos.',
                                ),
                              ),
                            );

                            return;
                          }

                          if (!correo
                              .contains('@')) {
                            ScaffoldMessenger
                                    .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingresa un correo válido.',
                                ),
                              ),
                            );

                            return;
                          }

                          if (password.length <
                              8) {
                            ScaffoldMessenger
                                    .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La contraseña debe tener mínimo 8 caracteres.',
                                ),
                              ),
                            );

                            return;
                          }

                          try {
                            setDialogState(() {
                              procesando = true;
                            });

                            await _perfilService
                                .crearUsuario(
                              nombre: nombre,
                              correo: correo,
                              password:
                                  password,
                              rol:
                                  rolSeleccionado,
                            );

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              true,
                            );
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }

                            setDialogState(() {
                              procesando = false;
                            });

                            ScaffoldMessenger
                                    .of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString(),
                                ),
                              ),
                            );
                          }
                        },
                  child: procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear usuario',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();

    if (resultado == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Usuario creado correctamente.',
          ),
        ),
      );

      setState(() {
        cargando = true;
      });

      await cargarUsuarios();
    }
  }

  Future<void> cambiarEstado(
    Perfil usuario,
  ) async {
    final idActual =
        _perfilService.obtenerIdUsuarioActual();

    if (usuario.id == idActual) {
      mostrarMensaje(
        'No puedes desactivar tu propio usuario.',
      );
      return;
    }

    final nuevoEstado =
        !usuario.activo;

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            nuevoEstado
                ? 'Activar usuario'
                : 'Desactivar usuario',
          ),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar a ${usuario.nombre}?'
                : '¿Deseas desactivar a ${usuario.nombre}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                nuevoEstado
                    ? 'Activar'
                    : 'Desactivar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _perfilService
          .actualizarEstadoUsuario(
        id: usuario.id,
        activo: nuevoEstado,
      );

      mostrarMensaje(
        nuevoEstado
            ? 'Usuario activado correctamente.'
            : 'Usuario desactivado correctamente.',
      );

      await cargarUsuarios();
    } catch (e) {
      mostrarMensaje(
        'Error: $e',
      );
    }
  }

  Future<void> cambiarRol(
    Perfil usuario,
  ) async {
    final idActual =
        _perfilService.obtenerIdUsuarioActual();

    if (usuario.id == idActual) {
      mostrarMensaje(
        'No puedes cambiar tu propio rol.',
      );
      return;
    }

    String rolSeleccionado =
        usuario.rol;

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Cambiar rol',
              ),
              content:
                  DropdownButtonFormField<
                      String>(
                initialValue:
                    rolSeleccionado,
                decoration:
                    const InputDecoration(
                  labelText: 'Rol',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'usuario',
                    child:
                        Text('Usuario'),
                  ),
                  DropdownMenuItem(
                    value:
                        'administrador',
                    child: Text(
                      'Administrador',
                    ),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setDialogState(() {
                      rolSeleccionado =
                          valor;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child:
                      const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child:
                      const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _perfilService
          .actualizarRolUsuario(
        id: usuario.id,
        rol: rolSeleccionado,
      );

      mostrarMensaje(
        'Rol actualizado correctamente.',
      );

      await cargarUsuarios();
    } catch (e) {
      mostrarMensaje(
        'Error: $e',
      );
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Gestión de Usuarios'),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: abrirFormularioUsuario,
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label:
            const Text('Nuevo usuario'),
      ),
      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : error != null
              ? _construirError()
              : _construirContenido(),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            const Text(
              'No fue posible cargar los usuarios.',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              error!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  cargando = true;
                  error = null;
                });

                cargarUsuarios();
              },
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    return Padding(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Usuarios registrados',
            style: TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${usuarios.length} usuario(s) registrado(s)',
            style: TextStyle(
              color:
                  Colors.grey[600],
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: usuarios.isEmpty
                ? const Center(
                    child: Text(
                      'No hay usuarios registrados.',
                    ),
                  )
                : ListView.separated(
                    itemCount:
                        usuarios.length,
                    separatorBuilder:
                        (_, _) =>
                            const SizedBox(
                      height: 10,
                    ),
                    itemBuilder:
                        (context, index) {
                      final usuario =
                          usuarios[index];

                      return _UsuarioCard(
                        usuario:
                            usuario,
                        onCambiarRol: () {
                          cambiarRol(
                            usuario,
                          );
                        },
                        onCambiarEstado: () {
                          cambiarEstado(
                            usuario,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UsuarioCard
    extends StatelessWidget {
  final Perfil usuario;
  final VoidCallback onCambiarRol;
  final VoidCallback onCambiarEstado;

  const _UsuarioCard({
    required this.usuario,
    required this.onCambiarRol,
    required this.onCambiarEstado,
  });

  @override
  Widget build(
      BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(
                usuario.esAdministrador
                    ? Icons
                        .admin_panel_settings
                    : Icons.person,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombre,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    usuario.correo,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          usuario.rol,
                        ),
                      ),

                      Chip(
                        avatar: Icon(
                          usuario.activo
                              ? Icons
                                  .check_circle
                              : Icons.cancel,
                          size: 18,
                          color:
                              usuario.activo
                                  ? Colors
                                      .green
                                  : Colors.red,
                        ),
                        label: Text(
                          usuario.activo
                              ? 'Activo'
                              : 'Inactivo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (valor) {
                if (valor ==
                    'rol') {
                  onCambiarRol();
                }

                if (valor ==
                    'estado') {
                  onCambiarEstado();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rol',
                  child: ListTile(
                    leading: Icon(
                      Icons
                          .admin_panel_settings_outlined,
                    ),
                    title: Text(
                      'Cambiar rol',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'estado',
                  child: ListTile(
                    leading: Icon(
                      usuario.activo
                          ? Icons
                              .person_off_outlined
                          : Icons
                              .person_outline,
                    ),
                    title: Text(
                      usuario.activo
                          ? 'Desactivar'
                          : 'Activar',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}