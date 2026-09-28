import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/perfil_model.dart';
import '../../controllers/road_incident_controller.dart';
import '../../services/road_incident_service.dart';
import '../../navigation/navigation_session.dart';
import '../../widgets/navigation_status_card.dart';
import '../../models/route_result.dart';
import '../../models/road_incident_report.dart';
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
import '../../widgets/user_location_marker.dart';
import '../../widgets/road_incident_marker.dart';
import '../../widgets/road_incident_details_sheet.dart';
import '../../widgets/road_incident_reports_sheet.dart';
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
    this.roadIncidentService,
  });
  final LocationService? locationService;
  final RoadIncidentService? roadIncidentService;
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
  late final _location = widget.locationService ?? LocationService();
  late final _routing = widget.routingService ?? OsrmRoutingService();
  late final _navigation = NavigationSession(
    _location,
    reroute: _routing.route,
  );
  late final _incidents = RoadIncidentController(
    widget.roadIncidentService ?? RoadIncidentService(),
  );
  Perfil? _perfil;
  bool _loadingProfile = false;
  bool _showProfileNotice = false;
  LatLng? _position;
  LocationStatus _locationStatus = LocationStatus.permissionNotRequested;
  bool _locating = false;
  bool _signingOut = false;
  RouteResult? _route;
  IncidentReportDraft? _reportDraft;
  IncidentReportDraft? _preparedReport;
  bool _reportOpen = false;
  bool _showPosition = true;
  bool _showRoute = true;
  bool _panelCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _navigation.addListener(_navigationChanged);
    _incidents.addListener(_incidentsChanged);
    _incidents.refresh();
    _loadProfile();
    _locate();
  }

  void _incidentsChanged() {
    if (mounted) setState(() {});
  }

  void _navigationChanged() {
    if (!mounted) return;
    setState(() {});
    final point = _navigation.currentPosition;
    if (_navigation.isActive && _navigation.following && point != null) {
      _followPosition(point);
    }
  }

  void _startNavigation(RouteResult route, String destination) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (!_navigation.start(route, destination)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No es posible iniciar esta ruta.')),
      );
      return;
    }
    setState(() {
      _showRoute = true;
      _showPosition = true;
    });
    if (_position != null) _followPosition(_position!);
  }

  void _followPosition(LatLng point) {
    final size = MediaQuery.sizeOf(context);
    // Mapa norte-arriba: desplazar el encuadre no supone heading del vehículo.
    _mapController.move(
      point,
      16,
      offset: Offset(
        size.width >= 700 ? size.width * .15 : 0,
        size.height < 600 ? -size.height * .04 : size.height * .06,
      ),
    );
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
    final result = await _location.locate();
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
    var published = false;
    await showModalBottomSheet<IncidentReportDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => AnimatedBuilder(
        animation: Listenable.merge([_incidents, _navigation]),
        builder: (context, _) => ReportIncidentSheet(
          currentPosition: _navigation.isActive
              ? _navigation.currentPosition
              : _position,
          initialDraft: _reportDraft,
          onDraftChanged: (draft) => _reportDraft = draft,
          onDiscard: () {
            setState(() {
              _reportDraft = null;
              _preparedReport = null;
            });
            Navigator.pop(context);
          },
          onPickLocation: (current) => Navigator.of(context).push<LatLng>(
            MaterialPageRoute(
              builder: (_) => ReportLocationPicker(
                currentPosition: _navigation.isActive
                    ? _navigation.currentPosition
                    : _position,
                initialCenter:
                    current ?? _position ?? _mapController.camera.center,
                route: _navigation.isActive ? _navigation.route : _route,
              ),
            ),
          ),
          onPublish: !_incidents.ready
              ? null
              : (draft) async {
                  await _incidents.publish(draft);
                  published = true;
                  if (!mounted) return;
                  setState(() {
                    _reportDraft = null;
                    _preparedReport = null;
                  });
                },
          onSubmit: (draft) {
            setState(() {
              _reportDraft = draft;
              _preparedReport = draft;
            });
            // The draft marker confirms the preview during navigation; a bottom
            // snackbar would cover the persistent Finish action.
            if (_navigation.isActive) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _incidents.ready
                      ? 'Borrador preparado. Aún no se ha publicado.'
                      : 'Borrador preparado. Envío de reportes pendiente de habilitación.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          },
        ),
      ),
    );
    _reportOpen = false;
    if (mounted && published && !_navigation.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reporte publicado correctamente.'),
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.sizeOf(context).height * .5,
          ),
        ),
      );
    }
  }

  void _showReportDetails(RoadIncidentReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (_) => RoadIncidentDetailsSheet(report: report),
    );
  }

  Future<void> _openReports() async {
    final report = await showModalBottomSheet<RoadIncidentReport>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      builder: (sheetContext) => RoadIncidentReportsSheet(
        controller: _incidents,
        onCreate: () {
          Navigator.pop(sheetContext);
          _openReportSheet();
        },
      ),
    );
    if (!mounted || report == null) return;
    if (_navigation.isActive) _navigation.pauseFollowing();
    _mapController.move(report.coordinates, 16);
    _showReportDetails(report);
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
    _incidents.removeListener(_incidentsChanged);
    _incidents.dispose();
    _navigation.removeListener(_navigationChanged);
    _navigation.dispose();
    _mapController.dispose();
    if (widget.routingService == null) _routing.dispose();
    super.dispose();
  }

  EdgeInsets _routePadding(Size size, bool wide) => EdgeInsets.fromLTRB(
    wide ? _wideMargin + _panelWideWidth + 16 : 48,
    wide ? _wideMargin + _headerReservedHeight : 84,
    48,
    wide ? 48 : (_panelCollapsed ? 64 : size.height * .48) + _compactMargin,
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
    final navigating = _navigation.isActive;
    final activeRoute = navigating ? _navigation.route : _route;
    final position = navigating ? _navigation.currentPosition : _position;
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppNavigationDrawer(
        perfil: _perfil,
        onHome: () => Navigator.pop(context),
        onRoutes: () => _open(const RutasScreen()),
        onRoadIncidents: () {
          Navigator.pop(context);
          _openReports();
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
          final short = !wide && constraints.maxHeight < 560;
          final edge = wide ? _wideMargin : _compactMargin;
          return Stack(
            children: [
              Positioned.fill(
                child: RouteMap(
                  initialPosition: _initialCenter,
                  mapController: _mapController,
                  expand: true,
                  autoFit: !navigating,
                  onManualMove: navigating ? _navigation.pauseFollowing : null,
                  fitPadding: activeRoute == null
                      ? const EdgeInsets.all(48)
                      : _routePadding(constraints.biggest, wide),
                  overlayMarkers: [
                    for (final report in _incidents.reports)
                      Marker(
                        point: report.coordinates,
                        width: 48,
                        height: 48,
                        alignment: Alignment.topLeft,
                        child: RoadIncidentMarker(
                          type: report.type,
                          published: true,
                          onTap: () => _showReportDetails(report),
                        ),
                      ),
                    if (_preparedReport case final draft?)
                      Marker(
                        point: draft.coordinates!,
                        width: 48,
                        height: 48,
                        alignment: Alignment.topLeft,
                        child: RoadIncidentMarker(
                          type: draft.type!,
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            constraints: const BoxConstraints(maxWidth: 560),
                            builder: (_) => RoadIncidentDetailsSheet(
                              draft: draft,
                              onEdit: () {
                                Navigator.pop(context);
                                _openReportSheet();
                              },
                              onDiscard: () {
                                setState(() {
                                  _preparedReport = null;
                                  _reportDraft = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                  markers: [
                    if (position != null && (_showPosition || navigating))
                      Marker(
                        point: position,
                        width: 52,
                        height: 52,
                        child: const UserLocationMarker(),
                      ),
                    if (activeRoute != null && activeRoute.origin != position)
                      Marker(
                        point: activeRoute.origin,
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
                    if (activeRoute != null)
                      Marker(
                        point: activeRoute.destination,
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
                    if (navigating && _navigation.projection != null)
                      Polyline(
                        points: _navigation.projection!.traveled,
                        strokeWidth: 4,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: .5,
                        ),
                      ),
                    if (activeRoute != null && _showRoute)
                      Polyline(
                        points: navigating
                            ? (_navigation.projection?.remaining ??
                                  activeRoute.points)
                            : activeRoute.points,
                        strokeWidth: 5,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
              if (!navigating)
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
              if (_showProfileNotice && !navigating && !short)
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
                            onPressed: () =>
                                setState(() => _showProfileNotice = false),
                            child: const Text('Ocultar'),
                          ),
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
                top: wide || navigating
                    ? edge
                    : edge + _headerReservedHeight + 8,
                child: SafeArea(
                  bottom: false,
                  child: navigating
                      ? FloatingActionButton.small(
                          heroTag: 'navigation-recenter',
                          tooltip: 'Recentrar',
                          onPressed: _navigation.recenter,
                          child: const Icon(Icons.my_location),
                        )
                      : MapFloatingControls(
                          onReports: _openReports,
                          reportsLoading: _incidents.loading,
                          reportsError: _incidents.error != null,
                          horizontal: short,
                          locating: _locating,
                          showPosition: _showPosition,
                          showRoute: _showRoute,
                          onShowPosition: (value) =>
                              setState(() => _showPosition = value),
                          onShowRoute: (value) =>
                              setState(() => _showRoute = value),
                          onLocate: () {
                            if (_position != null) {
                              setState(() => _showPosition = true);
                              _mapController.move(_position!, 15);
                            } else {
                              _locate();
                            }
                          },
                          onFitRoute: activeRoute == null
                              ? null
                              : () {
                                  setState(() => _showRoute = true);
                                  _fitRoute(constraints.biggest, wide);
                                },
                        ),
                ),
              ),
              if (navigating)
                Positioned(
                  left: edge,
                  top: edge,
                  width: wide
                      ? _panelWideWidth
                      : constraints.maxWidth - 2 * edge - 64,
                  child: SafeArea(
                    bottom: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .30,
                      ),
                      child: SingleChildScrollView(
                        child: NavigationManeuverCard(session: _navigation),
                      ),
                    ),
                  ),
                ),
              if (navigating)
                Positioned(
                  right: edge,
                  top: navigating
                      ? edge + (wide ? 128 : 64)
                      : edge + _headerReservedHeight + 8,
                  child: SafeArea(
                    bottom: false,
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Abrir menú de navegación',
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                          IconButton(
                            tooltip: 'Reportes de la vía',
                            onPressed: _openReports,
                            icon: const Icon(Icons.report_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: edge,
                top: navigating
                    ? short
                          ? edge + 176
                          : (wide
                                ? edge + 64
                                : edge + constraints.maxHeight * .30 + 8)
                    : wide
                    ? edge + 184
                    : null,
                bottom: wide || navigating
                    ? null
                    : (_panelCollapsed ? 64 : constraints.maxHeight * .48) +
                          2 * edge,
                child: SafeArea(
                  top: false,
                  child: short
                      ? FloatingActionButton.small(
                          heroTag: 'report-incident',
                          tooltip: 'Reportar novedad vial',
                          onPressed: _openReportSheet,
                          child: const Icon(Icons.add_location_alt_outlined),
                        )
                      : FloatingActionButton.extended(
                          heroTag: 'report-incident',
                          elevation: 3,
                          backgroundColor: colorScheme.surface,
                          foregroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tooltip: 'Reportar novedad vial',
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Reportar'),
                          onPressed: _openReportSheet,
                        ),
                ),
              ),
              Positioned(
                key: const ValueKey('route-panel'),
                left: edge,
                bottom: edge,
                width: wide ? _panelWideWidth : constraints.maxWidth - 2 * edge,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (navigating)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * .42,
                          ),
                          child: SingleChildScrollView(
                            child: NavigationStatusCard(session: _navigation),
                          ),
                        ),
                      Offstage(
                        key: const ValueKey('route-planner'),
                        offstage: navigating,
                        child: MapSearchPanel(
                          maxHeight: constraints.maxHeight * .48,
                          onCollapsedChanged: (collapsed) =>
                              setState(() => _panelCollapsed = collapsed),
                          currentPosition: _position,
                          onStartNavigation: _startNavigation,
                          locationStatus: _locationStatus,
                          geocodingService: widget.geocodingService,
                          placeSuggestionService: widget.placeSuggestionService,
                          routingService: _routing,
                          onRouteChanged: (result) =>
                              setState(() => _route = result),
                        ),
                      ),
                    ],
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
