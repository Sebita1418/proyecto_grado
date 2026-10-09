import 'package:flutter/material.dart';

import '../theme/mobility_theme.dart';

/// Shared section surface. Accepts observed content without computing data.
class MobilitySectionCard extends StatelessWidget {
  const MobilitySectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.margin,
  });
  final String title;
  final Widget child;
  final IconData? icon;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Card(
    margin: margin,
    child: Padding(
      padding: const EdgeInsets.all(MobilityDesign.pageInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
