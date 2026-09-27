import 'package:flutter/material.dart';

import '../models/perfil_model.dart';

enum AppDestination { home, routes, incidents, nearby, profile }

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
    this.destination = AppDestination.home,
  });

  final Perfil? perfil;
  final VoidCallback onHome, onRoutes, onNearby, onProfile, onSignOut;
  final VoidCallback? onAdmin, onRoadIncidents;
  final AppDestination destination;

  Widget _entry(AppDestination target, IconData icon, String label, VoidCallback? action) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    selected: destination == target,
    onTap: action,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListTileTheme(
                  data: ListTileThemeData(
                    selectedTileColor: colors.primaryContainer,
                    selectedColor: colors.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CircleAvatar(backgroundColor: colors.primaryContainer, foregroundColor: colors.onPrimaryContainer, child: const Icon(Icons.directions_bus_outlined)),
                          const SizedBox(height: 12),
                          Text('Transporte Inteligente', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Muévete mejor. Decide tu ruta.', style: theme.textTheme.bodySmall),
                          if (perfil != null) ...[
                            const Divider(height: 24),
                            Text(perfil!.nombre, style: theme.textTheme.titleSmall),
                            Text(perfil!.correo, style: theme.textTheme.bodySmall),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 12),
                      _entry(AppDestination.home, Icons.map_outlined, 'Mapa / Inicio', onHome),
                      _entry(AppDestination.routes, Icons.route_outlined, 'Rutas', onRoutes),
                      if (onRoadIncidents != null)
                        _entry(AppDestination.incidents, Icons.report_outlined, 'Reportes de la vía', onRoadIncidents),
                      _entry(AppDestination.nearby, Icons.place_outlined, 'Puntos cercanos', onNearby),
                      _entry(AppDestination.profile, Icons.person_outline, 'Perfil', onProfile),
                      if (onAdmin != null)
                        ListTile(leading: const Icon(Icons.admin_panel_settings_outlined), title: const Text('Administración'), onTap: onAdmin),
                      const Divider(),
                      ListTile(leading: const Icon(Icons.logout), title: const Text('Cerrar sesión'), onTap: onSignOut),
                    ],
                  ),
                ),
      ),
    );
  }
}
