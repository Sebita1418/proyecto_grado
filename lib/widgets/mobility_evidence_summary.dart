import 'package:flutter/material.dart';

import '../theme/mobility_theme.dart';

/// Navy summary from observed values only; never supplies demo defaults.
class MobilityEvidenceSummary extends StatelessWidget {
  const MobilityEvidenceSummary({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    this.badge,
    this.icon = Icons.insights_outlined,
  });
  final String label, value, detail;
  final String? badge;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: MobilityDesign.ink,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white70, letterSpacing: .8),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );
}
