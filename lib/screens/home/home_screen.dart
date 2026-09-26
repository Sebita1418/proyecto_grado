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
import '../../widgets/map_floating_controls.dart';
import '../../widgets/navigation_header.dart';
import '../../widgets/report_incident_sheet.dart';
import '../../widgets/report_location_picker.dart';
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

  /// Margins that keep every floating control detached from the viewport
  /// edges so the map stays the protagonist.
  static const double _wideMargin = 20;
  static const double _compactMargin = 12;
  static const double _panelWideWidth = 450;
  static const double _headerWideWidth = 420;

  /// Conservative reserved height for [NavigationHeader] so notices and
  /// floating controls never overlap it at large text scales.
  static const double _headerReservedHeight = 60;
  final MapController _mapController = MapController();
  Perfil? _perfil;
  bool _loadingProfile = false;
  bool _showProfileNotice = false;
  LatLng? _position;
  LocationStatus _locationStatus = LocationStatus.permissionNotRequested;
  bool _locating = false;
  bool _signingOut = false;
  RouteResult? _route;
  IncidentReportDraft? _reportDraft;
  bool _reportOpen = false;
  bool _showPosition = true;
  bool _showRoute = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _locate();
  }

  Future<void> _loadProfile() async {
    if (_loadingProfile) return;
    setState(() => _loadingProfile = true);
    Perfil? perfil;
    try {
      perfil =
          await (widget.loadProfile ?? PerfilService().obtenerPerfilActual)();
    } catch (_) {
      // A missing profile and a failed request both allow a local retry.
    }
    if (!mounted) return;
    setState(() {
      _perfil = perfil;
      _loadingProfile = false;
      _showProfileNotice = perfil == null;
    });
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

  void _openProfile() {
    if (_perfil != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PerfilScreen(perfil: _perfil!)),
      );
    } else {
      setState(() => _showProfileNotice = true);
    }
  }

  Future<void> _openReportSheet() async {
    if (_reportOpen) return;
    _reportOpen = true;
    await showModalBottomSheet<IncidentReportDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => ReportIncidentSheet(
        currentPosition: _position,
        initialDraft: _reportDraft,
        onDraftChanged: (draft) => _reportDraft = draft,
        onPickLocation: (current) => Navigator.of(context).push<LatLng>(
          MaterialPageRoute(
            builder: (_) => ReportLocationPicker(
              initialCenter:
                  current ?? _position ?? _mapController.camera.center,
              route: _route,
            ),
          ),
        ),
        onSubmit: (draft) {
          _reportDraft = draft;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Borrador preparado. Envío de reportes pendiente de habilitación.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        },
      ),
    );
    _reportOpen = false;
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
    wide ? _wideMargin + _panelWideWidth + 16 : 48,
    wide ? _wideMargin + _headerReservedHeight : 84,
    48,
    wide ? 48 : size.height * .48 + _compactMargin,
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
      key: _scaffoldKey,
      drawer: AppNavigationDrawer(
        perfil: _perfil,
        onHome: () => Navigator.pop(context),
        onRoutes: () => _open(const RutasScreen()),
        onRoadIncidents: () {
          Navigator.pop(context);
          _openReportSheet();
        },
        onNearby: () => _open(const NearbyPlacesScreen()),
        onProfile: () {
          if (_perfil != null) {
            _open(PerfilScreen(perfil: _perfil!));
          } else {
            Navigator.pop(context);
            setState(() => _showProfileNotice = true);
          }
        },
        onAdmin: _perfil?.esAdministrador == true
            ? () => _open(const AdminScreen())
            : null,
        onSignOut: _signingOut ? () {} : _signOut,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          final edge = wide ? _wideMargin : _compactMargin;
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
                    if (position != null && _showPosition)
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
                    if (_route != null && _showRoute)
                      Polyline(
                        points: _route!.points,
                        strokeWidth: 5,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: edge,
                top: edge,
                width: wide
                    ? _headerWideWidth
                    : constraints.maxWidth - 2 * edge,
                child: SafeArea(
                  bottom: false,
                  child: NavigationHeader(
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    onProfilePressed: _openProfile,
                    userAvatar:
                        _perfil == null || _perfil!.nombre.trim().isEmpty
                        ? null
                        : CircleAvatar(
                            radius: 15,
                            child: Text(
                              _perfil!.nombre
                                  .trim()
                                  .characters
                                  .first
                                  .toUpperCase(),
                            ),
                          ),
                  ),
                ),
              ),
              if (_showProfileNotice)
                Positioned(
                  left: edge,
                  top: edge + _headerReservedHeight + 8,
                  width: wide
                      ? _headerWideWidth
                      : constraints.maxWidth - 2 * edge - 64,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .30,
                    ),
                    child: SingleChildScrollView(
                      child: MaterialBanner(
                        forceActionsBelow: true,
                        content: Text(
                          _loadingProfile
                              ? 'Cargando tu perfil. Puedes seguir usando el mapa.'
                              : 'No fue posible cargar tu perfil. Puedes seguir usando el mapa.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        actions: [
                          TextButton(
                            onPressed: _loadingProfile ? null : _loadProfile,
                            child: Text(
                              _loadingProfile ? 'Cargando…' : 'Reintentar',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: edge,
                top: wide ? edge : edge + _headerReservedHeight + 8,
                child: SafeArea(
                  bottom: false,
                  child: MapFloatingControls(
                    locating: _locating,
                    showPosition: _showPosition,
                    showRoute: _showRoute,
                    onShowPosition: (value) =>
                        setState(() => _showPosition = value),
                    onShowRoute: (value) => setState(() => _showRoute = value),
                    onLocate: () {
                      if (_position != null) {
                        setState(() => _showPosition = true);
                        _mapController.move(_position!, 15);
                      } else {
                        _locate();
                      }
                    },
                    onFitRoute: _route == null
                        ? null
                        : () {
                            setState(() => _showRoute = true);
                            _fitRoute(constraints.biggest, wide);
                          },
                  ),
                ),
              ),
              Positioned(
                right: edge,
                bottom: wide ? edge : constraints.maxHeight * .48 + 2 * edge,
                child: SafeArea(
                  top: false,
                  child: FloatingActionButton.extended(
                    heroTag: 'report-incident',
                    tooltip: 'Reportar novedad vial',
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Reportar'),
                    onPressed: _openReportSheet,
                  ),
                ),
              ),
              Positioned(
                left: edge,
                bottom: edge,
                width: wide ? _panelWideWidth : constraints.maxWidth - 2 * edge,
                child: SafeArea(
                  top: false,
                  child: MapSearchPanel(
                    currentPosition: position,
                    locationStatus: _locationStatus,
                    geocodingService: widget.geocodingService,
                    placeSuggestionService: widget.placeSuggestionService,
                    routingService: widget.routingService,
                    onRouteChanged: (result) => setState(() => _route = result),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
