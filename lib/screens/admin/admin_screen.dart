import 'package:flutter/material.dart';

import 'rutas/rutas_admin_screen.dart';
import 'usuarios/usuarios_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel de Administración',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Administración',
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Gestiona la información principal del sistema.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _AdminCard(
                    icon:
                        Icons.people_outline,
                    title: 'Usuarios',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const UsuariosScreen(),
                        ),
                      );
                    },
                  ),

                  _AdminCard(
                    icon: Icons
                        .directions_bus_outlined,
                    title: 'Rutas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RutasAdminScreen(),
                        ),
                      );
                    },
                  ),

                  const _AdminCard(
                    icon: Icons
                        .location_on_outlined,
                    title: 'Paradas',
                  ),

                  const _AdminCard(
                    icon: Icons
                        .analytics_outlined,
                    title: 'Reportes',
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

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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
            const SizedBox(
              height: 12,
            ),
            Text(
              title,
              textAlign:
                  TextAlign.center,
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