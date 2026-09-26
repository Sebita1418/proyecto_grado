import 'package:flutter/material.dart';

import '../models/perfil_model.dart';

/// Navigation drawer for application-wide routing and shortcuts.
///
/// Contains direct access to Map, Routes, Road Incident Reports,
/// Nearby Places, Profile, and Administration (if authorized).
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
    this.onRoadIncidents,
  });

  final Perfil? perfil;
  final VoidCallback onHome, onRoutes, onNearby, onProfile, onSignOut;
  final VoidCallback? onAdmin;
  final VoidCallback? onRoadIncidents;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: const Icon(Icons.directions_bus_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transporte Inteligente',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Muévete mejor. Decide tu ruta.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (perfil != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  dense: true,
                  tileColor: colors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(
                    perfil!.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    perfil!.correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            const Divider(indent: 16, endIndent: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Mapa / Inicio'),
                    selected: true,
                    selectedTileColor: colors.primaryContainer,
                    selectedColor: colors.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: onHome,
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_bus_outlined),
                    title: const Text('Rutas'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: onRoutes,
                  ),
                  ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: const Text('Reportes de la vía'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: onRoadIncidents,
                  ),
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('Puntos cercanos'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: onNearby,
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Perfil'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: onProfile,
                  ),
                  if (onAdmin != null)
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Administración'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: onAdmin,
                    ),
                ],
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: onSignOut,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
