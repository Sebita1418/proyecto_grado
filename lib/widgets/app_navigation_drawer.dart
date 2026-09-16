import 'package:flutter/material.dart';

import '../models/perfil_model.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    this.perfil,
    required this.onHome,
    required this.onRoutes,
    required this.onNearby,
    required this.onProfile,
    required this.onSignOut,
    this.onAdmin,
  });
  final Perfil? perfil;
  final VoidCallback onHome, onRoutes, onNearby, onProfile, onSignOut;
  final VoidCallback? onAdmin;

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transporte Inteligente',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (perfil != null) ...[
                  const SizedBox(height: 8),
                  Text(perfil!.nombre),
                  Text(
                    perfil!.correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Mapa / Inicio'),
            onTap: onHome,
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus_outlined),
            title: const Text('Rutas'),
            onTap: onRoutes,
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Puntos cercanos'),
            onTap: onNearby,
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: onProfile,
          ),
          if (onAdmin != null)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Administración'),
              onTap: onAdmin,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: onSignOut,
          ),
        ],
      ),
    ),
  );
}
