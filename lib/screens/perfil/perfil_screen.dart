import 'package:flutter/material.dart';

import '../../models/perfil_model.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key, required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),

          CircleAvatar(
            radius: 48,
            child: Text(
              _obtenerInicial(perfil.nombre),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            perfil.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            perfil.correo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),

          const SizedBox(height: 28),

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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
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
                      fontSize: 16,
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
