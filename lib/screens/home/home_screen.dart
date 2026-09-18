import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/perfil_model.dart';
import '../../models/route_result.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/osrm_routing_service.dart';
import '../../services/place_suggestion_service.dart';
import '../../services/perfil_service.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/map_search_panel.dart';
import '../../widgets/route_map.dart';
import '../admin/admin_screen.dart';
import '../login/login_screen.dart';
import '../nearby/nearby_places_screen.dart';
import '../perfil/perfil_screen.dart';
import '../rutas/rutas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.locationService,
    this.loadProfile,
    this.geocodingService,
    this.routingService,
    this.placeSuggestionService,
  });
  final LocationService? locationService;
  final Future<Perfil?> Function()? loadProfile;
  final GeocodingService? geocodingService;
  final OsrmRoutingService? routingService;
  final PlaceSuggestionService? placeSuggestionService;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _initialCenter = LatLng(7.119349, -73.122742);
  final MapController _mapController = MapController();
  Perfil? _perfil;
  LatLng? _position;
  LocationStatus _locationStatus = LocationStatus.permissionNotRequested;
  bool _locating = false;
  bool _signingOut = false;
  RouteResult? _route;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _locate();
  }

  Future<void> _loadProfile() async {
    try {
      final perfil =
          await (widget.loadProfile ?? PerfilService().obtenerPerfilActual)();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // The map remains available when profile loading fails.
    }
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await (widget.locationService ?? LocationService()).locate();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationStatus = result.status;
      _position = result.coordinates;
      _route = null;
    });
    if (result.coordinates != null) {
      _mapController.move(result.coordinates!, 15);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_locationMessage(result.status))));
    }
  }

  String _locationMessage(LocationStatus status) => switch (status) {
    LocationStatus.serviceDisabled =>
      'Activa la ubicación del dispositivo o escribe un origen.',
    LocationStatus.permissionDenied =>
      'Permiso de ubicación denegado. Puedes escribir un origen.',
    LocationStatus.permissionDeniedForever =>
      'Habilita la ubicación en ajustes o escribe un origen.',
    _ => 'No pudimos obtener tu ubicación. Puedes escribir un origen.',
  };

  void _open(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _signOut() async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar la sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible cerrar la sesión.')),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  EdgeInsets _routePadding(Size size, bool wide) => EdgeInsets.fromLTRB(
    wide ? 440 : 48,
    48,
    48,
    wide ? 48 : size.height * .58 + 16,
  );

  void _fitRoute(Size size, bool wide) {
    final route = _route;
    if (route == null || route.points.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(route.points),
        padding: _routePadding(size, wide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final position = _position;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.directions_bus_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Transporte Inteligente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Muévete mejor. Decide tu ruta.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: AppNavigationDrawer(
        perfil: _perfil,
        onHome: () => Navigator.pop(context),
        onRoutes: () => _open(const RutasScreen()),
        onNearby: () => _open(const NearbyPlacesScreen()),
        onProfile: () {
          if (_perfil != null) _open(PerfilScreen(perfil: _perfil!));
        },
        onAdmin: _perfil?.esAdministrador == true
            ? () => _open(const AdminScreen())
            : null,
        onSignOut: _signingOut ? () {} : _signOut,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          return Stack(
            children: [
              Positioned.fill(
                child: RouteMap(
                  initialPosition: _initialCenter,
                  mapController: _mapController,
                  expand: true,
                  fitPadding: _route == null
                      ? const EdgeInsets.all(48)
                      : _routePadding(constraints.biggest, wide),
                  markers: [
                    if (position != null)
                      Marker(
                        point: position,
                        width: 52,
                        height: 52,
                        child: Tooltip(
                          message: 'Mi ubicación',
                          child: Semantics(
                            label: 'Marcador de mi ubicación',
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withValues(
                                      alpha: .25,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 10,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_route != null && _route!.origin != position)
                      Marker(
                        point: _route!.origin,
                        width: 48,
                        height: 48,
                        child: Tooltip(
                          message: 'Origen',
                          child: Icon(
                            Icons.trip_origin,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    if (_route != null)
                      Marker(
                        point: _route!.destination,
                        width: 48,
                        height: 48,
                        child: Tooltip(
                          message: 'Destino',
                          child: Icon(
                            Icons.location_on,
                            size: 38,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ),
                  ],
                  polylines: [
                    if (_route != null)
                      Polyline(
                        points: _route!.points,
                        strokeWidth: 5,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'current-location',
                      tooltip: 'Mi ubicación',
                      onPressed: _locating
                          ? null
                          : () {
                              if (_position != null) {
                                _mapController.move(_position!, 15);
                              } else {
                                _locate();
                              }
                            },
                      child: _locating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                    if (_route != null) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'full-route',
                        tooltip: 'Ver ruta completa',
                        onPressed: () => _fitRoute(constraints.biggest, wide),
                        child: const Icon(Icons.fit_screen),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: wide ? 20 : 8,
                bottom: wide ? 20 : 8,
                width: wide ? 420 : constraints.maxWidth - 16,
                child: MapSearchPanel(
                  currentPosition: position,
                  locationStatus: _locationStatus,
                  geocodingService: widget.geocodingService,
                  placeSuggestionService: widget.placeSuggestionService,
                  routingService: widget.routingService,
                  onRouteChanged: (result) => setState(() => _route = result),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
