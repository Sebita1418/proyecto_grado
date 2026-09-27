import 'package:flutter/material.dart';

/// GPS position only: no heading is inferred from the route or map camera.
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tu ubicación actual',
    child: Tooltip(
      message: 'Tu ubicación actual',
      excludeFromSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1565C0).withValues(alpha: .16),
          border: Border.all(color: const Color(0x331565C0)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1565C0),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x400D47A1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
