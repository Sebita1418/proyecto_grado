import 'package:flutter/material.dart';

import '../models/perfil_model.dart';
import '../theme/mobility_theme.dart';

enum AppDestination {
  home,
  routes,
  incidents,
  analytics,
  validation,
  nearby,
  profile,
}

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
    this.onAnalytics,
    this.onValidation,
    this.destination = AppDestination.home,
  });

  final Perfil? perfil;
  final VoidCallback onHome, onRoutes, onNearby, onProfile, onSignOut;
  final VoidCallback? onAdmin, onRoadIncidents, onAnalytics, onValidation;
  final AppDestination destination;

  Widget _entry(
    AppDestination target,
    IconData icon,
    String label,
    VoidCallback? action,
  ) => ListTile(
    iconColor: Colors.white70,
    textColor: Colors.white,
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
      backgroundColor: MobilityDesign.ink,
      child: SafeArea(
        child: ListTileTheme(
          data: ListTileThemeData(
            selectedTileColor: Colors.white.withValues(alpha: .1),
            selectedColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.route_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Transporte Inteligente',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Muévete mejor. Decide tu ruta.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (perfil != null) ...[
                      const Divider(height: 24),
                      Text(
                        perfil!.nombre,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        perfil!.correo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'MOVILIDAD',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _entry(
                AppDestination.home,
                Icons.map_outlined,
                'Mapa / Inicio',
                onHome,
              ),
              _entry(
                AppDestination.routes,
                Icons.route_outlined,
                'Rutas',
                onRoutes,
              ),
              if (onRoadIncidents != null)
                _entry(
                  AppDestination.incidents,
                  Icons.report_outlined,
                  'Reportes de la vía',
                  onRoadIncidents,
                ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'EVIDENCIA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (onAnalytics != null)
                _entry(
                  AppDestination.analytics,
                  Icons.bar_chart_outlined,
                  'Analítica de movilidad',
                  onAnalytics,
                ),
              Tooltip(
                message: onValidation == null
                    ? 'Calcula una recomendación vehicular para validar.'
                    : 'Validación de recomendación',
                child: _entry(
                  AppDestination.validation,
                  Icons.verified_user_outlined,
                  'Validación de recomendación',
                  onValidation,
                ),
              ),
              _entry(
                AppDestination.nearby,
                Icons.place_outlined,
                'Puntos cercanos',
                onNearby,
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'CUENTA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _entry(
                AppDestination.profile,
                Icons.person_outline,
                'Perfil',
                onProfile,
              ),
              if (onAdmin != null)
                ListTile(
                  iconColor: Colors.white70,
                  textColor: Colors.white,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Administración'),
                  onTap: onAdmin,
                ),
              const Divider(),
              ListTile(
                iconColor: MobilityDesign.danger,
                textColor: Colors.white,
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
