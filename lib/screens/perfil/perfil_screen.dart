import 'package:flutter/material.dart';

import '../../models/perfil_model.dart';
import '../preferences/mobility_preferences_screen.dart';
import '../../services/location_service.dart';
import '../../theme/mobility_theme.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({
    super.key,
    required this.perfil,
    this.locationStatus,
    this.authenticated,
    this.provider,
    this.onSignOut,
  });

  final Perfil perfil;
  final LocationStatus? locationStatus;
  final bool? authenticated;
  final String? provider;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        toolbarHeight: MobilityDesign.appBarHeight(
          MediaQuery.textScalerOf(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Text(
                      _obtenerInicial(perfil.nombre),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perfil.nombre, style: theme.textTheme.titleMedium),

                        const SizedBox(height: 6),

                        Text(
                          perfil.correo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authenticated == null
                              ? 'Sesión no verificada'
                              : authenticated!
                              ? 'Sesión autenticada'
                              : 'Sesión no disponible',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: authenticated == true
                                ? MobilityDesign.positive
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CUENTA',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
          ),
          _PerfilInfoCard(
            icon: Icons.my_location,
            label: 'Permiso de ubicación',
            value: switch (locationStatus) {
              LocationStatus.coordinatesObtained => 'Ubicación obtenida',
              LocationStatus.permissionGranted => 'Permiso concedido',
              LocationStatus.permissionDenied => 'Permiso denegado',
              LocationStatus.permissionDeniedForever => 'Permiso bloqueado',
              LocationStatus.serviceDisabled => 'GPS desactivado',
              _ => 'Estado no disponible',
            },
          ),
          _PerfilInfoCard(
            icon: Icons.login_outlined,
            label: 'Proveedor de cuenta',
            value: provider == 'google'
                ? 'Google'
                : provider == 'email'
                ? 'Correo electrónico'
                : provider ?? 'No disponible',
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Preferencias de movilidad'),
              subtitle: const Text('Configura tus modos de transporte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MobilityPreferencesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ExpansionTile(
            title: const Text('Información de cuenta'),
            children: [
              _PerfilInfoCard(
                icon: Icons.person_outline,
                label: 'Nombre',
                value: perfil.nombre,
              ),

              const SizedBox(height: 12),

              _PerfilInfoCard(
                icon: Icons.email_outlined,
                label: 'Correo electrónico',
                value: perfil.correo,
              ),

              const SizedBox(height: 12),

              _PerfilInfoCard(
                icon: Icons.badge_outlined,
                label: 'Rol',
                value: _formatearRol(perfil.rol),
              ),

              const SizedBox(height: 12),

              _PerfilInfoCard(
                icon: perfil.activo
                    ? Icons.check_circle_outline
                    : Icons.block_outlined,
                label: 'Estado de la cuenta',
                value: perfil.activo ? 'Activa' : 'Inactiva',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ACERCA DE',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
          ),
          const _PerfilInfoCard(
            icon: Icons.info_outline,
            label: 'Transporte Inteligente',
            value: 'Proyecto académico de movilidad',
          ),
          const _PerfilInfoCard(
            icon: Icons.shield_outlined,
            label: 'Privacidad y datos',
            value: 'Ubicación para consultar rutas y navegar. Indicadores históricos agregados.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: MobilityDesign.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  static String _obtenerInicial(String nombre) {
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      return '?';
    }

    return nombreLimpio.substring(0, 1).toUpperCase();
  }

  static String _formatearRol(String rol) {
    switch (rol) {
      case 'administrador':
        return 'Administrador';
      case 'usuario':
        return 'Usuario';
      default:
        return rol;
    }
  }
}

class _PerfilInfoCard extends StatelessWidget {
  const _PerfilInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
