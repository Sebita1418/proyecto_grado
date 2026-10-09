import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import 'route_map.dart';

/// Edits only a draft coordinate. It never requests or changes a route.
class ReportLocationPicker extends StatefulWidget {
  const ReportLocationPicker({
    super.key,
    required this.initialCenter,
    this.route,
    this.currentPosition,
    this.title = 'Ubicación del reporte',
    this.pointLabel = 'Ubicación del borrador de novedad',
    this.instruction = 'Toca el mapa para colocar el marcador del borrador.',
    this.validationMessage,
    this.boundaryPolygons = const [],
  });

  final String title, pointLabel, instruction;
  final LatLng initialCenter;
  final RouteResult? route;
  final LatLng? currentPosition;
  final String? Function(LatLng point)? validationMessage;
  final List<List<List<LatLng>>> boundaryPolygons;

  @override
  State<ReportLocationPicker> createState() => _ReportLocationPickerState();
}

class _ReportLocationPickerState extends State<ReportLocationPicker> {
  LatLng? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final coverageMessage = _selected == null
        ? null
        : widget.validationMessage?.call(_selected!);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          Positioned.fill(
            child: RouteMap(
              initialPosition: widget.initialCenter,
              expand: true,
              autoFit: false,
              boundaryPolygons: widget.boundaryPolygons,
              onTap: (point) => setState(() => _selected = point),
              polylines: [
                if (widget.route != null)
                  Polyline(
                    points: widget.route!.points,
                    color: colors.primary,
                    strokeWidth: 5,
                  ),
              ],
              markers: [
                if (widget.route != null) ...[
                  Marker(
                    point: widget.route!.origin,
                    child: const Tooltip(
                      message: 'Origen de la ruta',
                      child: Icon(Icons.trip_origin),
                    ),
                  ),
                  Marker(
                    point: widget.route!.destination,
                    child: const Tooltip(
                      message: 'Destino de la ruta',
                      child: Icon(Icons.location_on),
                    ),
                  ),
                ],
                if (_selected != null)
                  Marker(
                    point: _selected!,
                    width: 56,
                    height: 56,
                    child: Semantics(
                      container: true,
                      label: widget.pointLabel,
                      child: Icon(
                        Icons.add_location_alt,
                        size: 48,
                        color: colors.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.sizeOf(context).height * .65,
                ),
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _selected == null
                                  ? widget.instruction
                                  : '${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}. Toca otro punto para moverlo.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (coverageMessage != null)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                coverageMessage,
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                          if (widget.currentPosition != null)
                            OutlinedButton.icon(
                              onPressed: () => setState(
                                () => _selected = widget.currentPosition,
                              ),
                              icon: const Icon(Icons.my_location),
                              label: const Text('Usar mi ubicación'),
                            ),
                          FilledButton.icon(
                            onPressed:
                                _selected == null || coverageMessage != null
                                ? null
                                : () => Navigator.pop(context, _selected),
                            icon: const Icon(Icons.check),
                            label: const Text('Confirmar ubicación'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
