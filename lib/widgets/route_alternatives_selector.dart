import 'package:flutter/material.dart';

import '../models/route_result.dart';

/// Presents provider order without ranking or requesting more routes.
class RouteAlternativesSelector extends StatefulWidget {
  const RouteAlternativesSelector({
    super.key,
    required this.alternatives,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RouteResult> alternatives;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<RouteAlternativesSelector> createState() =>
      _RouteAlternativesSelectorState();
}

class _RouteAlternativesSelectorState extends State<RouteAlternativesSelector> {
  ModalRoute<int>? _pickerRoute;

  @override
  void dispose() {
    final route = _pickerRoute;
    // GPS changes can invalidate the result while its picker is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route != null && route.isActive) route.navigator?.removeRoute(route);
    });
    super.dispose();
  }

  Future<void> _open(BuildContext context) async {
    final alternatives = widget.alternatives;
    final selectedIndex = widget.selectedIndex;
    final index = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        _pickerRoute = ModalRoute.of<int>(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Alternativas de ruta vehicular',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alternatives.length,
                  itemBuilder: (context, index) {
                    final route = alternatives[index];
                    final selected = index == selectedIndex;
                    return Semantics(
                      button: true,
                      child: ListTile(
                        selected: selected,
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text('Alternativa ${index + 1}'),
                        subtitle: Text(
                          '${(route.distanceMeters / 1000).toStringAsFixed(1)} km'
                          ' · Duración estimada: '
                          '${(route.durationSeconds / 60).round()} min'
                          '${selected ? '\nSeleccionada' : ''}',
                        ),
                        onTap: () => Navigator.pop(context, index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    _pickerRoute = null;
    if (mounted && index != null) widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
    child: widget.alternatives.length == 1
        ? const Text('Se recibió una sola ruta vehicular.')
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  'Alternativa ${widget.selectedIndex + 1} de '
                  '${widget.alternatives.length} seleccionada',
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.alt_route),
                label: const Text('Cambiar alternativa'),
              ),
            ],
          ),
  );
}
