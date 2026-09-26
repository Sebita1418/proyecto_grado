import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../mobility/transport_mode.dart';
import '../../services/mobility_preferences_service.dart';

/// Device-local selection using the same type as MobilityContext.allowedModes.
class MobilityPreferencesScreen extends StatefulWidget {
  const MobilityPreferencesScreen({
    super.key,
    this.onConfirmed,
    this.service = const MobilityPreferencesService(),
  });

  final MobilityPreferencesService service;

  /// Optional consumer receives a non-empty, immutable selection.
  final ValueChanged<Set<TransportMode>>? onConfirmed;

  @override
  State<MobilityPreferencesScreen> createState() =>
      _MobilityPreferencesScreenState();
}

class _MobilityPreferencesScreenState extends State<MobilityPreferencesScreen> {
  Set<TransportMode> _selected = {};
  Set<TransportMode> _confirmed = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final modes = await widget.service.load();
      if (!mounted) return;
      setState(() {
        _selected = Set.of(modes);
        _confirmed = Set.of(modes);
        _loading = false;
      });
    } on MobilityPreferencesStorageException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'No se pudieron cargar las preferencias. '
            'Puedes elegir y confirmar una nueva selección.';
      });
    }
  }

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

  Future<void> _confirm() async {
    if (_selected.isEmpty || !_hasChanges || _saving) return;
    final modes = Set<TransportMode>.unmodifiable(_selected);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.save(modes);
    } on MobilityPreferencesStorageException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'No se pudieron guardar las preferencias. '
            'Intenta confirmar de nuevo.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _confirmed = modes;
      _saving = false;
    });
    widget.onConfirmed?.call(modes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de movilidad')),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando preferencias',
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
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
                          'Elige uno o varios modos permitidos para las recomendaciones. '
                          'Actualmente solo se calculan rutas vehiculares. '
                          'Los cambios se aplican al volver a calcular y no confirman '
                          'que haya transporte disponible.',
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
                                  onChanged: _saving
                                      ? null
                                      : (selected) => setState(() {
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
                          'La selección confirmada se guarda en este dispositivo; '
                          'no se guarda en tu cuenta.',
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _selected.isEmpty
                                ? 'Selecciona al menos un modo para confirmar.'
                                : _hasChanges
                                ? 'Tienes cambios sin confirmar.'
                                : 'Preferencias guardadas en este dispositivo.',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_saving)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Guardando preferencias',
                          ),
                        if (_error != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed:
                                  !_saving &&
                                      _selected.isNotEmpty &&
                                      _hasChanges
                                  ? _confirm
                                  : null,
                              icon: const Icon(Icons.check),
                              label: const Text('Confirmar selección'),
                            ),
                            OutlinedButton.icon(
                              onPressed: !_saving && _hasChanges
                                  ? () => setState(
                                      () => _selected = Set.of(_confirmed),
                                    )
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
