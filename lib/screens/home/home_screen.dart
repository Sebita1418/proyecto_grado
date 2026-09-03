import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/perfil_model.dart';
import '../../services/perfil_service.dart';

import '../admin/admin_screen.dart';
import '../login/login_screen.dart';
import '../rutas/rutas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PerfilService _perfilService = PerfilService();

  Perfil? perfil;

  bool cargando = true;
  bool cerrandoSesion = false;

  String? error;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    try {
      final perfilActual =
          await _perfilService.obtenerPerfilActual();

      if (!mounted) return;

      setState(() {
        perfil = perfilActual;
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

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Deseas cerrar la sesión actual?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    if (!mounted) return;

    setState(() {
      cerrandoSesion = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cerrandoSesion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible cerrar la sesión: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Transporte Inteligente',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No fue posible cargar el perfil.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final perfilActual = perfil!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transporte Inteligente',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed:
                cerrandoSesion ? null : cerrarSesion,
            icon: cerrandoSesion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.logout,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${perfilActual.nombre} 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Rol: ${perfilActual.rol}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '¿Qué deseas consultar?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  const _MenuCard(
                    icon: Icons.map_outlined,
                    title: 'Mapa',
                  ),

                  _MenuCard(
                    icon: Icons.directions_bus_outlined,
                    title: 'Rutas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RutasScreen(),
                        ),
                      );
                    },
                  ),

                  const _MenuCard(
                    icon:
                        Icons.location_on_outlined,
                    title: 'Puntos cercanos',
                  ),

                  const _MenuCard(
                    icon: Icons.person_outline,
                    title: 'Perfil',
                  ),

                  if (perfilActual.esAdministrador)
                    _MenuCard(
                      icon: Icons
                          .admin_panel_settings_outlined,
                      title: 'Administración',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}