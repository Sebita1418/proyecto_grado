import 'package:flutter/material.dart';

/// Floating navigation header for the modern map experience.
///
/// Features a compact surface card with menu action, brand icon,
/// app title, subtitle, and profile shortcut.
class NavigationHeader extends StatelessWidget {
  const NavigationHeader({
    super.key,
    required this.onMenuPressed,
    this.onProfilePressed,
    this.userAvatar,
    this.title = 'Transporte Inteligente',
    this.subtitle = 'Muévete mejor. Decide tu ruta.',
  });

  final VoidCallback onMenuPressed;
  final VoidCallback? onProfilePressed;
  final Widget? userAvatar;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 6,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Abrir menú de navegación',
                onPressed: onMenuPressed,
              ),
              if (MediaQuery.sizeOf(context).width >= 400)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.directions_bus_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: title,
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: userAvatar ?? const Icon(Icons.person_outline),
                tooltip: 'Perfil',
                onPressed: onProfilePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
