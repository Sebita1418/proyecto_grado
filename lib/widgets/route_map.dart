import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.initialPosition,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.onMapCreated,
    this.onTap,
  });

  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final ValueChanged<LatLng>? onTap;

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
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            onMapCreated: onMapCreated,
            onTap: onTap,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
        ),
      ),
    );
  }
}
