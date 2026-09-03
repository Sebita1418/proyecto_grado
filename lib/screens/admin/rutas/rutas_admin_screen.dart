import 'package:flutter/material.dart';

import '../../../models/ruta_model.dart';
import '../../../services/ruta_service.dart';

class RutasAdminScreen extends StatefulWidget {
  const RutasAdminScreen({super.key});

  @override
  State<RutasAdminScreen> createState() =>
      _RutasAdminScreenState();
}

class _RutasAdminScreenState
    extends State<RutasAdminScreen> {
  final RutaService _rutaService = RutaService();

  bool cargando = true;
  String? error;

  List<Ruta> rutas = [];

  @override
  void initState() {
    super.initState();
    cargarRutas();
  }

  Future<void> cargarRutas() async {
    try {
      final resultado =
          await _rutaService.obtenerRutas();

      if (!mounted) return;

      setState(() {
        rutas = resultado;
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

  Future<void> abrirFormularioRuta({
    Ruta? ruta,
  }) async {
    final nombreController =
        TextEditingController(
      text: ruta?.nombre ?? '',
    );

    final origenController =
        TextEditingController(
      text: ruta?.origen ?? '',
    );

    final destinoController =
        TextEditingController(
      text: ruta?.destino ?? '',
    );

    final descripcionController =
        TextEditingController(
      text: ruta?.descripcion ?? '',
    );

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
              title: Text(
                ruta == null
                    ? 'Nueva ruta'
                    : 'Editar ruta',
              ),
              content: SizedBox(
                width: 440,
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
                              'Nombre de la ruta',
                          prefixIcon: Icon(
                            Icons
                                .directions_bus_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            origenController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Origen',
                          prefixIcon: Icon(
                            Icons.trip_origin,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            destinoController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Destino',
                          prefixIcon: Icon(
                            Icons
                                .location_on_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            descripcionController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Descripción',
                          prefixIcon: Icon(
                            Icons
                                .description_outlined,
                          ),
                        ),
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
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                ElevatedButton(
                  onPressed: procesando
                      ? null
                      : () async {
                          final nombre =
                              nombreController
                                  .text
                                  .trim();

                          final origen =
                              origenController
                                  .text
                                  .trim();

                          final destino =
                              destinoController
                                  .text
                                  .trim();

                          final descripcion =
                              descripcionController
                                  .text
                                  .trim();

                          if (nombre.isEmpty ||
                              origen.isEmpty ||
                              destino.isEmpty) {
                            ScaffoldMessenger
                                    .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nombre, origen y destino son obligatorios.',
                                ),
                              ),
                            );

                            return;
                          }

                          try {
                            setDialogState(() {
                              procesando = true;
                            });

                            if (ruta == null) {
                              await _rutaService
                                  .crearRuta(
                                nombre: nombre,
                                origen: origen,
                                destino: destino,
                                descripcion:
                                    descripcion,
                              );
                            } else {
                              await _rutaService
                                  .actualizarRuta(
                                id: ruta.id,
                                nombre: nombre,
                                origen: origen,
                                destino: destino,
                                descripcion:
                                    descripcion,
                              );
                            }

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
                                  'Error: $e',
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
                      : Text(
                          ruta == null
                              ? 'Crear ruta'
                              : 'Guardar cambios',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    origenController.dispose();
    destinoController.dispose();
    descripcionController.dispose();

    if (resultado == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            ruta == null
                ? 'Ruta creada correctamente.'
                : 'Ruta actualizada correctamente.',
          ),
        ),
      );

      setState(() {
        cargando = true;
      });

      await cargarRutas();
    }
  }

  Future<void> cambiarEstadoRuta(
    Ruta ruta,
  ) async {
    final nuevoEstado = !ruta.activa;

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            nuevoEstado
                ? 'Activar ruta'
                : 'Desactivar ruta',
          ),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar la ruta "${ruta.nombre}"?'
                : '¿Deseas desactivar la ruta "${ruta.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
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
      await _rutaService.cambiarEstadoRuta(
        id: ruta.id,
        activa: nuevoEstado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? 'Ruta activada correctamente.'
                : 'Ruta desactivada correctamente.',
          ),
        ),
      );

      await cargarRutas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Gestión de Rutas'),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          abrirFormularioRuta();
        },
        icon: const Icon(
          Icons.add_road,
        ),
        label: const Text(
          'Nueva ruta',
        ),
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
            const SizedBox(
              height: 16,
            ),
            const Text(
              'No fue posible cargar las rutas.',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              error!,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  cargando = true;
                  error = null;
                });

                cargarRutas();
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
            'Rutas registradas',
            style: TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            '${rutas.length} ruta(s) registrada(s)',
            style: TextStyle(
              color:
                  Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: rutas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay rutas registradas.',
                    ),
                  )
                : ListView.separated(
                    itemCount:
                        rutas.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 10,
                    ),
                    itemBuilder:
                        (context, index) {
                      final ruta =
                          rutas[index];

                      return _RutaCard(
                        ruta: ruta,
                        onEditar: () {
                          abrirFormularioRuta(
                            ruta: ruta,
                          );
                        },
                        onCambiarEstado: () {
                          cambiarEstadoRuta(
                            ruta,
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

class _RutaCard extends StatelessWidget {
  final Ruta ruta;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  const _RutaCard({
    required this.ruta,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(
                ruta.activa
                    ? Icons
                        .directions_bus
                    : Icons
                        .directions_bus_filled_outlined,
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta.nombre,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '${ruta.origen} → ${ruta.destino}',
                  ),
                  if (ruta.descripcion !=
                          null &&
                      ruta.descripcion!
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      ruta.descripcion!,
                      style: TextStyle(
                        color:
                            Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 10,
                  ),
                  Chip(
                    avatar: Icon(
                      ruta.activa
                          ? Icons
                              .check_circle
                          : Icons.cancel,
                      size: 18,
                      color: ruta.activa
                          ? Colors.green
                          : Colors.red,
                    ),
                    label: Text(
                      ruta.activa
                          ? 'Activa'
                          : 'Inactiva',
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (valor) {
                if (valor == 'editar') {
                  onEditar();
                }

                if (valor == 'estado') {
                  onCambiarEstado();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    leading: Icon(
                      Icons.edit_outlined,
                    ),
                    title: Text(
                      'Editar',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'estado',
                  child: ListTile(
                    leading: Icon(
                      ruta.activa
                          ? Icons
                              .block_outlined
                          : Icons
                              .check_circle_outline,
                    ),
                    title: Text(
                      ruta.activa
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