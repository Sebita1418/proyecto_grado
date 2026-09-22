import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../mobility/transport_mode.dart';

/// Local selection using the same type as MobilityContext.allowedModes.
/// No persistence or recommendation engine is invoked by this screen.
class MobilityPreferencesScreen extends StatefulWidget {
  const MobilityPreferencesScreen({super.key, this.onConfirmed});

  /// Optional consumer receives a non-empty, immutable selection.
  final ValueChanged<Set<TransportMode>>? onConfirmed;

  @override
  State<MobilityPreferencesScreen> createState() =>
      _MobilityPreferencesScreenState();
}

class _MobilityPreferencesScreenState extends State<MobilityPreferencesScreen> {
  Set<TransportMode> _selected = {};
  Set<TransportMode> _confirmed = {};

  bool get _hasChanges => !setEquals(_selected, _confirmed);

  String _label(TransportMode mode) => switch (mode) {
    TransportMode.driving => 'En vehículo',
    TransportMode.walking => 'A pie',
    TransportMode.cycling => 'En bicicleta',
    TransportMode.publicTransport => 'Transporte público',
  };

  IconData _icon(TransportMode mode) => switch (mode) {
    TransportMode.driving => Icons.directions_car_outlined,
    TransportMode.walking => Icons.directions_walk,
    TransportMode.cycling => Icons.directions_bike,
    TransportMode.publicTransport => Icons.directions_bus_outlined,
  };

  void _confirm() {
    if (_selected.isEmpty || !_hasChanges) return;
    final modes = Set<TransportMode>.unmodifiable(_selected);
    setState(() => _confirmed = modes);
    widget.onConfirmed?.call(modes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de movilidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tune, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      '¿Cómo te gustaría desplazarte?',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige uno o varios modos para futuras recomendaciones. '
                    'Esta selección todavía no cambia las rutas calculadas '
                    'ni confirma que haya transporte disponible.',
                  ),
                  const SizedBox(height: 20),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final mode in TransportMode.values)
                          CheckboxListTile(
                            title: Text(_label(mode)),
                            secondary: Icon(_icon(mode)),
                            value: _selected.contains(mode),
                            onChanged: (selected) => setState(() {
                              if (selected == true) {
                                _selected.add(mode);
                              } else {
                                _selected.remove(mode);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'La selección se conserva solo mientras esta pantalla '
                    'esté abierta. Al salir se pierde; no se guarda en tu cuenta.',
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _selected.isEmpty
                          ? 'Selecciona al menos un modo para confirmar.'
                          : _hasChanges
                          ? 'Tienes cambios sin confirmar.'
                          : 'Preferencias confirmadas en esta pantalla.',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _selected.isNotEmpty && _hasChanges
                            ? _confirm
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar selección'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _hasChanges
                            ? () =>
                                  setState(() => _selected = Set.of(_confirmed))
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Deshacer cambios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
