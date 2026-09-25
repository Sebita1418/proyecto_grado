import 'package:flutter/material.dart';

import '../models/route_result.dart';
import '../services/route_alternatives_analysis_service.dart';

/// Compares provider metrics without reordering or requesting more routes.
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
    final analysis = const RouteAlternativesAnalysisService().analyze(
      alternatives,
    );
    final index = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      builder: (context) {
        _pickerRoute = ModalRoute.of<int>(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Diferencias: tiempo frente a la más rápida; distancia frente a la más corta.',
                ),
              ),
              Expanded(
                child: ListView.builder(
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
                          '${_duration(route.durationSeconds)}'
                          '\n${_comparison(analysis, index)}'
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
  Widget build(BuildContext context) => widget.alternatives.isEmpty
      ? const SizedBox.shrink()
      : Padding(
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

  String _comparison(RouteAlternativesAnalysis analysis, int index) {
    final difference = analysis.differences[index];
    return [
      if (index == analysis.fastestIndex) 'Más rápida',
      if (index == analysis.shortestIndex) 'Más corta',
      if (difference.extraSeconds > 0)
        difference.extraSeconds < 60
            ? '<1 min'
            : '+${_duration(difference.extraSeconds)}',
      if (difference.extraMeters > 0)
        _distanceDifference(difference.extraMeters),
    ].join(' · ');
  }

  // Same minute/hour convention as the result card. Its getters are widget-bound
  // and owned by PR #27; no shared formatter exists in this baseline.
  String _duration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours h' : '$hours h $remaining min';
  }

  String _distanceDifference(double meters) {
    if (meters < 1) return '<1 m';
    if (meters < 1000) return '+${meters.round()} m';
    return '+${(meters / 1000).toStringAsFixed(1)} km';
  }
}
