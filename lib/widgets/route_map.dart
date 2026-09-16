import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.initialPosition,
    this.markers = const <Marker>[],
    this.polylines = const <Polyline>[],
    this.mapController,
    this.onTap,
  });

  final LatLng initialPosition;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final MapController? mapController;
  final ValueChanged<LatLng>? onTap;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  late final MapController _mapController =
      widget.mapController ?? MapController();
  late final bool _ownsMapController = widget.mapController == null;
  bool _mapIsReady = false;

  @override
  void dispose() {
    if (_ownsMapController) _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_haveSameMarkerPoints(oldWidget.markers, widget.markers)) {
      _scheduleMarkerFit();
    }
  }

  bool _haveSameMarkerPoints(List<Marker> previous, List<Marker> current) {
    if (previous.length != current.length) return false;

    for (var index = 0; index < previous.length; index++) {
      if (previous[index].point != current[index].point) return false;
    }

    return true;
  }

  void _onMapReady() {
    _mapIsReady = true;
    _scheduleMarkerFit();
  }

  void _scheduleMarkerFit() {
    if (!_mapIsReady || widget.markers.length < 2) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapIsReady || widget.markers.length < 2) return;

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(
            widget.markers.map((marker) => marker.point).toList(),
          ),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mapa de consulta de ruta',
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 320,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 14,
              minZoom: 5,
              maxZoom: 19,
              onMapReady: _onMapReady,
              onTap: widget.onTap == null
                  ? null
                  : (_, point) => widget.onTap!(point),
              keepAlive: true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.transporteinteligente.app',
              ),
              if (widget.polylines.isNotEmpty)
                PolylineLayer(polylines: widget.polylines),
              if (widget.markers.isNotEmpty)
                MarkerLayer(markers: widget.markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
