import 'dart:async';

import 'package:flutter/material.dart';

import '../services/address_query.dart';
import '../models/road_incident_report.dart';
import '../mobility/route_incident_analysis.dart';
import '../mobility/route_incident_analyzer.dart';
import 'route_incident_status.dart';

import 'package:latlong2/latlong.dart';

import '../mobility/mobility_context.dart';
import '../mobility/mobility_recommendation.dart';
import '../mobility/decision/departure_time_context.dart';
import '../mobility/mobility_recommendation_engine.dart';
import '../mobility/route_option.dart';
import '../mobility/transport_mode.dart';
import '../mobility/vehicle_recommendation_engine.dart';
import '../services/mobility_preferences_service.dart';
import '../services/route_alternatives_analysis_service.dart';
import 'mobility_recommendation_summary.dart';
import 'travel_mode_selector.dart';
import '../models/place_suggestion.dart';
import '../models/geocoding_result.dart';
import '../models/route_result.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/place_suggestion_service.dart';
import '../services/osrm_routing_service.dart';
import 'route_planner_form.dart';
import 'route_result_card.dart';
import 'route_alternatives_selector.dart';
import 'departure_time_selector.dart';
import '../theme/mobility_theme.dart';

class MapSearchPanel extends StatefulWidget {
  const MapSearchPanel({
    super.key,
    required this.currentPosition,
    required this.locationStatus,
    this.geocodingService,
    this.placeSuggestionService,
    this.routingService,
    this.onRouteChanged,
    this.onStartNavigation,
    this.preferencesService = const MobilityPreferencesService(),
    this.recommendationEngine,
    this.maxHeight,
    this.onCollapsedChanged,
    this.incidentReports = const [],
    this.reportsAvailable = true,
  });
  final LatLng? currentPosition;
  final LocationStatus locationStatus;
  final GeocodingService? geocodingService;
  final PlaceSuggestionService? placeSuggestionService;
  final OsrmRoutingService? routingService;
  final ValueChanged<RouteResult?>? onRouteChanged;
  final void Function(RouteResult route, String destination)? onStartNavigation;
  final MobilityPreferencesService preferencesService;
  final MobilityRecommendationEngine? recommendationEngine;
  final double? maxHeight;
  final ValueChanged<bool>? onCollapsedChanged;
  final List<RoadIncidentReport> incidentReports;
  final bool reportsAvailable;
  @override
  State<MapSearchPanel> createState() => _MapSearchPanelState();
}

class _MapSearchPanelState extends State<MapSearchPanel> {
  final _scrollController = ScrollController();
  bool _collapsed = false;
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  String _lastOriginText = '';
  String _lastDestinationText = '';
  late final _geocoding = widget.geocodingService ?? GeocodingService();
  late final _suggestions =
      widget.placeSuggestionService ?? PlaceSuggestionService();
  late final _routing = widget.routingService ?? OsrmRoutingService();
  late final _engine =
      widget.recommendationEngine ?? VehicleRecommendationEngine();
  MobilityRecommendation? _recommendation;
  bool _updatingRecommendation = false;
  final _incidentAnalyses = ValueNotifier<List<RouteIncidentAnalysis>>([]);
  MobilityContext? _tripContext;
  List<RouteOption> _options = const [];
  int _incidentEvaluation = 0;
  int? _suggestedAlternative;
  bool _manuallySelected = false;
  bool _usesDefaultModes = false;
  String? _recommendationNotice;
  Timer? _debounce;
  Timer? _originDebounce;
  int _request = 0;
  int _originRequest = 0;
  bool _manualOrigin = false;
  bool _loadingSuggestions = false;
  bool _loadingOriginSuggestions = false;
  bool _checking = false;
  String? _phase;
  List<RouteResult> _alternatives = const [];
  int? _selectedAlternative;
  RouteResult? get _route => _selectedAlternative == null
      ? null
      : _alternatives[_selectedAlternative!];
  bool _showEditor = true;
  String _routeOriginLabel = '';
  String _routeDestinationLabel = '';
  int _calculation = 0;
  String? _suggestionError;
  String? _originSuggestionError;
  String? _originError;
  String? _destinationError;
  List<PlaceSuggestion> _places = [];
  List<PlaceSuggestion> _originPlaces = [];
  PlaceSuggestion? _selected;
  PlaceSuggestion? _selectedOrigin;
  TransportMode _selectedMode = TransportMode.driving;
  DepartureTimeContext _departure = DepartureTimeContext.now(DateTime.now());

  Widget _planningOptions() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DepartureTimeSelector(
        value: _departure,
        enabled: !_checking && !_updatingRecommendation,
        onChanged: (value) => setState(() => _departure = value),
      ),
      const SizedBox(height: 16),
      Text(
        'Opciones de movilidad',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      TravelModeSelector(
        compact: false,
        selectedMode:
            _tripContext?.allowedModes.contains(_selectedMode) == false
            ? null
            : _selectedMode,
        scheduled: _departure.isScheduled,
        vehicleEvaluated: _options.isNotEmpty && _recommendation != null,
        analyzing: _checking || _updatingRecommendation,
        vehicleAllowed:
            _tripContext?.allowedModes.contains(TransportMode.driving) ?? true,
        onModeSelected: (mode) => setState(() => _selectedMode = mode),
        onUnavailableModeTap: (mode) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mode == TransportMode.driving
                  ? 'Vehículo no está incluido en tus preferencias de movilidad.'
                  : mode == TransportMode.publicTransport
                  ? 'Aún no hay datos integrados de transporte público.'
                  : 'Aún no hay rutas disponibles para ${mode.label.toLowerCase()}.',
            ),
          ),
        ),
      ),
    ],
  );

  @override
  void didUpdateWidget(covariant MapSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition) {
      ++_calculation;
      _checking = false;
      _phase = null;
      _clearAlternatives();
      _showEditor = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRouteChanged?.call(null);
      });
    } else if (oldWidget.incidentReports != widget.incidentReports ||
        oldWidget.reportsAvailable != widget.reportsAvailable) {
      // A picker may be open in another route. Notify it after this build.
      ++_incidentEvaluation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshIncidentRecommendation());
      });
    }
  }

  List<RouteIncidentAnalysis> _analyzeIncidents(List<RouteResult> routes) {
    if (!widget.reportsAvailable) return const [];
    final now = DateTime.now().toUtc();
    return [
      for (var i = 0; i < routes.length; i++)
        const RouteIncidentAnalyzer().analyze(
          routeId: 'osrm-$i',
          geometry: routes[i].points,
          reports: widget.incidentReports,
          now: now,
        ),
    ];
  }

  MobilityContext _withIncidents(
    MobilityContext trip,
    List<RouteIncidentAnalysis> analyses,
  ) => MobilityContext(
    origin: trip.origin,
    destination: trip.destination,
    allowedModes: trip.allowedModes,
    requestedAt: trip.requestedAt,
    generalConditions: trip.generalConditions,
    incidentAnalyses: {
      for (final analysis in analyses) analysis.routeId: analysis,
    },
  );

  Future<void> _refreshIncidentRecommendation() async {
    final trip = _tripContext;
    if (trip == null || _alternatives.isEmpty) return;
    final evaluation = ++_incidentEvaluation;
    final calculation = _calculation;
    final analyses = _analyzeIncidents(_alternatives);
    _incidentAnalyses.value = analyses;
    setState(() => _updatingRecommendation = true);
    try {
      final recommendation = await _engine.recommend(
        _withIncidents(trip, analyses),
        _options,
      );
      if (!mounted ||
          evaluation != _incidentEvaluation ||
          calculation != _calculation) {
        return;
      }
      final index = _options.indexWhere(
        (o) => o.id == recommendation.recommended.id,
      );
      if (index < 0) throw StateError('Unknown recommended route');
      setState(() {
        _recommendation = recommendation;
        _updatingRecommendation = false;
        _suggestedAlternative = index;
        _recommendationNotice = null;
      });
      // Deliberately preserve selection and geometry, including during navigation.
    } catch (_) {
      if (!mounted ||
          evaluation != _incidentEvaluation ||
          calculation != _calculation) {
        return;
      }
      setState(() {
        _updatingRecommendation = false;
        _recommendation = null;
        _recommendationNotice =
            'No se pudo actualizar la recomendación; se conserva tu selección.';
      });
    }
  }

  void _invalidate() {
    _recommendationNotice = null;
    ++_calculation;
    _checking = false;
    _phase = null;
    if (_route != null) {
      _clearAlternatives();
      _showEditor = true;
      widget.onRouteChanged?.call(null);
    }
  }

  void _clearAlternatives() {
    ++_incidentEvaluation;
    _tripContext = null;
    _options = const [];
    _alternatives = const [];
    _selectedAlternative = null;
    _recommendation = null;
    _updatingRecommendation = false;
    _suggestedAlternative = null;
    _manuallySelected = false;
    _usesDefaultModes = false;
    _recommendationNotice = null;
  }

  void _selectAlternative(int index, int calculation) {
    // A picker opened for an earlier calculation must not change current data.
    if (!mounted ||
        calculation != _calculation ||
        _checking ||
        index < 0 ||
        index >= _alternatives.length) {
      return;
    }
    setState(() {
      _selectedAlternative = index;
      _manuallySelected = true;
    });
    widget.onRouteChanged?.call(_route);
  }

  @override
  void initState() {
    super.initState();
    _destination.addListener(_onDestinationChanged);
    _origin.addListener(_onOriginChanged);
  }

  void _onOriginChanged() {
    final text = _origin.text;
    if (text == _lastOriginText) return;
    _lastOriginText = text;
    _invalidate();
    _selectedOrigin = null;
    final query = _origin.text.trim();
    final request = ++_originRequest;
    _originDebounce?.cancel();
    setState(() {
      _originPlaces = [];
      _originSuggestionError = null;
      _loadingOriginSuggestions = query.length >= 3;
    });
    if (query.length < 3) return;
    _originDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchOrigin(query, request),
    );
  }

  Future<void> _searchOrigin(String query, int request) async {
    _suggestions.searchBias = widget.currentPosition;
    try {
      final results = await _suggestions
          .search(query)
          .timeout(const Duration(seconds: 10));
      if (!mounted || request != _originRequest) return;
      setState(() => _originPlaces = results);
    } catch (_) {
      if (!mounted || request != _originRequest) return;
      setState(
        () => _originSuggestionError = 'No fue posible buscar lugares. Puedes calcular con el texto escrito.',
      );
    } finally {
      if (mounted && request == _originRequest) {
        setState(() => _loadingOriginSuggestions = false);
      }
    }
  }

  void _selectOrigin(PlaceSuggestion place) {
    _invalidate();
    _originDebounce?.cancel();
    ++_originRequest;
    _origin.removeListener(_onOriginChanged);
    _origin.text = place.displayText;
    _lastOriginText = _origin.text;
    _origin.addListener(_onOriginChanged);
    setState(() {
      _selectedOrigin = place;
      _originPlaces = [];
      _originSuggestionError = null;
      _loadingOriginSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _onDestinationChanged() {
    final text = _destination.text;
    if (text == _lastDestinationText) return;
    _lastDestinationText = text;
    _invalidate();
    _selected = null;
    final query = _destination.text.trim();
    final request = ++_request;
    _debounce?.cancel();
    setState(() {
      _places = [];
      _suggestionError = null;
      _loadingSuggestions = query.length >= 3;
    });
    if (query.length < 3) return;
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _search(query, request),
    );
  }

  Future<void> _search(String query, int request) async {
    _suggestions.searchBias = widget.currentPosition;
    try {
      final results = await _suggestions
          .search(query)
          .timeout(const Duration(seconds: 10));
      if (!mounted || request != _request) return;
      setState(() => _places = results);
    } on TimeoutException {
      if (!mounted || request != _request) return;
      setState(
        () => _suggestionError = 'La búsqueda tardó demasiado. Puedes calcular con el texto escrito.',
      );
    } on PlaceSuggestionException catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _suggestionError = error.message);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(
        () => _suggestionError = 'No fue posible buscar lugares. Puedes calcular con el texto escrito.',
      );
    } finally {
      if (mounted && request == _request) {
        setState(() => _loadingSuggestions = false);
      }
    }
  }

  void _select(PlaceSuggestion place) {
    _invalidate();
    _debounce?.cancel();
    ++_request;
    _destination.removeListener(_onDestinationChanged);
    _destination.text = place.displayText;
    _lastDestinationText = _destination.text;
    _destination.addListener(_onDestinationChanged);
    setState(() {
      _selected = place;
      _places = [];
      _suggestionError = null;
      _loadingSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _calculate() async {
    if (_checking) return;
    if (_departure.isScheduled) {
      _message(
        'La planificación no tiene predicciones. Vuelve a Ahora para analizar las rutas.',
      );
      return;
    }
    final hasGps = widget.currentPosition != null && !_manualOrigin;
    final originText = _origin.text.trim();
    final destinationText = _destination.text.trim();
    setState(() {
      _originError = !hasGps && originText.isEmpty
          ? 'Escribe un origen.'
          : null;
      _destinationError = destinationText.isEmpty
          ? 'Escribe un destino.'
          : null;
    });
    if (_originError != null || _destinationError != null) return;
    // Resolve addresses visibly before routing, including approximate matches.
    if (!hasGps &&
        _selectedOrigin == null &&
        AddressQuery.isAddress(originText)) {
      await _findAddress(origin: true);
      return;
    }
    if (_selected == null && AddressQuery.isAddress(destinationText)) {
      await _findAddress(origin: false);
      return;
    }
    _geocoding.searchBias = widget.currentPosition;
    final calculation = ++_calculation;
    final requestedAt = DateTime.now();
    setState(() {
      _checking = true;
      _phase = 'Buscando lugares...';
      _clearAlternatives();
    });
    widget.onRouteChanged?.call(null);
    try {
      final origin = hasGps
          ? widget.currentPosition!
          : _selectedOrigin != null
          ? LatLng(_selectedOrigin!.latitude, _selectedOrigin!.longitude)
          : _point(
              await _geocoding
                  .search(originText)
                  .timeout(const Duration(seconds: 10)),
            );
      if (!mounted || calculation != _calculation) return;
      if (origin == null) {
        throw const GeocodingException('No se encontró el origen.');
      }
      final destination = _selected != null
          ? LatLng(_selected!.latitude, _selected!.longitude)
          : _point(
              await _geocoding
                  .search(destinationText)
                  .timeout(const Duration(seconds: 10)),
            );
      if (!mounted || calculation != _calculation) return;
      if (destination == null) {
        throw const GeocodingException('No se encontró el destino.');
      }
      setState(() => _phase = 'Calculando ruta...');
      final results = await _routing
          .routeAlternatives(origin: origin, destination: destination)
          .timeout(const Duration(seconds: 20));
      if (!mounted || calculation != _calculation) return;
      if (results.isEmpty) {
        throw const OsrmRoutingException('El servicio no devolvió una ruta.');
      }
      setState(() => _phase = 'Evaluando alternativas...');
      // Reload for every calculation, including after returning from Profile.
      // A storage failure must never be treated as an empty preference set.
      final savedModes = await widget.preferencesService.load();
      if (!mounted || calculation != _calculation) return;
      final usesDefaultModes = savedModes.isEmpty;
      final context = MobilityContext(
        origin: origin,
        destination: destination,
        allowedModes: usesDefaultModes ? {TransportMode.driving} : savedModes,
        requestedAt: requestedAt,
      );
      final options = [
        for (var index = 0; index < results.length; index++)
          RouteOption.fromRouteResult(
            id: 'osrm-$index',
            mode: TransportMode.driving,
            route: results[index],
            source: 'osrm',
          ),
      ];
      final reportSnapshot = widget.incidentReports;
      final availableSnapshot = widget.reportsAvailable;
      final incidentAnalyses = _analyzeIncidents(results);
      _tripContext = context;
      _options = options;
      _incidentAnalyses.value = incidentAnalyses;
      final recommendation = await _engine.recommend(
        _withIncidents(context, incidentAnalyses),
        options,
      );
      if (!mounted || calculation != _calculation) return;
      final suggestedIndex = options.indexWhere(
        (option) => option.id == recommendation.recommended.id,
      );
      if (suggestedIndex < 0) throw StateError('Unknown recommended route');
      setState(() {
        _tripContext = context;
        _options = options;
        _incidentAnalyses.value = incidentAnalyses;
        _alternatives = List.unmodifiable(results);
        // Recommendation explains the options; it does not choose for the user.
        _selectedAlternative = 0;
        _suggestedAlternative = suggestedIndex;
        _recommendation = recommendation;
        _usesDefaultModes = usesDefaultModes;
        _showEditor = false;
        _routeOriginLabel = hasGps ? 'Tu ubicación actual' : originText;
        _routeDestinationLabel = _selected?.name ?? destinationText;
      });
      widget.onRouteChanged?.call(_route);
      if (reportSnapshot != widget.incidentReports ||
          availableSnapshot != widget.reportsAvailable) {
        unawaited(_refreshIncidentRecommendation());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } on NoEligibleVehicleRouteException {
      if (mounted && calculation == _calculation) {
        setState(
          () => _recommendationNotice =
              'Todavía no hay una ruta compatible con los modos elegidos. '
              'Solo se calculan rutas vehiculares. Puedes revisar tus preferencias '
              'desde Perfil y volver a calcular; tus puntos se conservan.',
        );
      }
    } on MobilityPreferencesStorageException {
      if (mounted && calculation == _calculation) {
        setState(
          () => _recommendationNotice =
              'No se pudieron leer las preferencias. No se seleccionó una ruta. '
              'Vuelve a calcular para reintentar.',
        );
      }
    } on TimeoutException {
      if (mounted && calculation == _calculation) {
        _message('La consulta tardó demasiado. Intenta de nuevo.');
      }
    } on OsrmRoutingException catch (error) {
      if (mounted && calculation == _calculation) _message(error.message);
    } on GeocodingException catch (error) {
      if (mounted && calculation == _calculation) _message(error.message);
    } catch (_) {
      if (mounted && calculation == _calculation) {
        _message('No fue posible calcular la ruta. Intenta de nuevo.');
      }
    } finally {
      if (mounted && calculation == _calculation) {
        setState(() {
          _checking = false;
          _phase = null;
        });
      }
    }
  }

  // Explicit search only: public Nominatim is not an autocomplete provider.
  Future<void> _findAddress({required bool origin}) async {
    final query = (origin ? _origin : _destination).text.trim();
    if (query.isEmpty || _checking) return;
    (origin ? _originDebounce : _debounce)?.cancel();
    final request = origin ? ++_originRequest : ++_request;
    setState(() {
      if (origin) {
        _loadingOriginSuggestions = true;
        _originSuggestionError = null;
      } else {
        _loadingSuggestions = true;
        _suggestionError = null;
      }
    });
    try {
      _geocoding.searchBias = widget.currentPosition;
      final results = await _geocoding.resolve(
        query,
        isCurrent: () =>
            mounted && request == (origin ? _originRequest : _request),
      );
      if (!mounted || request != (origin ? _originRequest : _request)) return;
      final places = results.map((result) {
        final parts = result.displayName.split(',');
        final titleParts =
            parts.length > 1 &&
                RegExp(r'^\s*\d+[\w-]*\s*$').hasMatch(parts.first)
            ? 2
            : 1;
        return PlaceSuggestion(
          name: result.road != null && result.houseNumber != null
              ? '${result.road} # ${result.houseNumber}'
              : parts.take(titleParts).join(',').trim(),
          description: parts.skip(titleParts).join(',').trim(),
          latitude: result.latitude,
          longitude: result.longitude,
          precision: result.precision,
          road: result.road,
          houseNumber: result.houseNumber,
          city: result.city,
        );
      }).toList();
      setState(() {
        if (origin) {
          _originPlaces = places;
          _originSuggestionError = places.isEmpty
              ? 'No se encontró esa dirección. Añade la ciudad o revisa la numeración.'
              : null;
        } else {
          _places = places;
          _suggestionError = places.isEmpty
              ? 'No se encontró esa dirección. Añade la ciudad o revisa la numeración.'
              : null;
        }
      });
    } catch (_) {
      if (!mounted || request != (origin ? _originRequest : _request)) return;
      setState(() {
        if (origin) {
          _originSuggestionError =
              'No fue posible buscar la dirección. Reintenta.';
        } else {
          _suggestionError = 'No fue posible buscar la dirección. Reintenta.';
        }
      });
    } finally {
      if (mounted && request == (origin ? _originRequest : _request)) {
        setState(() {
          if (origin) {
            _loadingOriginSuggestions = false;
          } else {
            _loadingSuggestions = false;
          }
        });
      }
    }
  }

  Widget? _addressResults({required bool origin, Widget? child}) {
    final query = (origin ? _origin : _destination).text;
    final selected = origin ? _selectedOrigin : _selected;
    if (selected?.precision != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(selected!.precision!.label),
      );
    }
    if (!AddressQuery.isAddress(query) || selected != null) return child;
    final loading = origin ? _loadingOriginSuggestions : _loadingSuggestions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?child,
        TextButton.icon(
          onPressed: loading || _checking
              ? null
              : () => _findAddress(origin: origin),
          icon: const Icon(Icons.search),
          label: Text(
            origin ? 'Buscar dirección de origen' : 'Buscar dirección',
          ),
        ),
      ],
    );
  }

  LatLng? _point(GeocodingResult? result) =>
      result == null ? null : LatLng(result.latitude, result.longitude);

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Widget _assistiveError(String message) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
    child: Tooltip(
      message: message,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 17,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.startsWith('No se encontró esa dirección') ? message : 'No hay sugerencias disponibles. Puedes escribir y calcular.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _searchingPlaces() => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text('Buscando lugares...'),
          ),
        ),
      ],
    ),
  );

  Widget? _emptySuggestions(String query, PlaceSuggestion? selected) =>
      query.trim().length < 3 || selected != null
      ? null
      : const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Sin sugerencias. Puedes calcular con la dirección escrita.',
          ),
        );

  @override
  void dispose() {
    ++_incidentEvaluation;
    _incidentAnalyses.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _originDebounce?.cancel();
    ++_request;
    ++_originRequest;
    _origin.dispose();
    _destination.dispose();
    if (widget.geocodingService == null) _geocoding.dispose();
    if (widget.placeSuggestionService == null) _suggestions.dispose();
    if (widget.routingService == null) _routing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasGps = widget.currentPosition != null && !_manualOrigin;
    final height = MediaQuery.sizeOf(context).height;
    final calculation = _calculation;
    final colorScheme = Theme.of(context).colorScheme;
    final analysis = _route == null
        ? null
        : const RouteAlternativesAnalysisService().analyze(_alternatives);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: widget.maxHeight ?? height * .46,
      ),
      child: Material(
        elevation: 8,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobilityDesign.sheetRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 18),
                    Expanded(
                      child: _collapsed
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _route == null
                                      ? '¿A dónde vas?'
                                      : _routeDestinationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (_route != null)
                                  Text(
                                    '${_departure.isScheduled ? 'Referencia de Ahora · ' : ''}'
                                    '${(_route!.durationSeconds / 60).ceil()} min · '
                                    '${(_route!.distanceMeters / 1000).toStringAsFixed(1)} km',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                              ],
                            )
                          : Center(
                              child: Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                    ),
                    IconButton(
                      tooltip: _collapsed
                          ? 'Expandir panel de ruta'
                          : 'Minimizar panel de ruta',
                      icon: Icon(
                        _collapsed ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _collapsed = !_collapsed);
                        widget.onCollapsedChanged?.call(_collapsed);
                      },
                    ),
                  ],
                ),
                if (!_collapsed) ...[
                  if (_route != null && !_showEditor) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _routeDestinationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: _planningOptions(),
                    ),
                    if (_recommendation != null && _departure.isNow)
                      MobilityRecommendationSummary(
                        incidentAnalyses: _incidentAnalyses.value,
                        updating: _updatingRecommendation,
                        compact: true,
                        recommendation: _recommendation!,
                        suggestedIndex: _suggestedAlternative!,
                        selectedIndex: _selectedAlternative!,
                        manuallySelected: _manuallySelected,
                        usesDefaultModes: _usesDefaultModes,
                      ),
                    RouteResultCard(
                      route: _route!,
                      referenceOnly: _departure.isScheduled,
                      onStart:
                          widget.onStartNavigation == null ||
                              _departure.isScheduled
                          ? null
                          : () => widget.onStartNavigation!(
                              _route!,
                              _routeDestinationLabel,
                            ),
                      originLabel: _routeOriginLabel,
                      destinationLabel: _routeDestinationLabel,
                      onModify: () => setState(() => _showEditor = true),
                      fastest:
                          _alternatives.length > 1 &&
                          analysis?.fastestIndex == _selectedAlternative,
                      shortest:
                          _alternatives.length > 1 &&
                          analysis?.shortestIndex == _selectedAlternative,
                    ),
                    RouteAlternativesSelector(
                      suggestedIndex:
                          _departure.isScheduled ||
                              _updatingRecommendation ||
                              _recommendation == null
                          ? null
                          : _suggestedAlternative,
                      manuallySelected: _manuallySelected,
                      incidentAnalyses: _incidentAnalyses,
                      alternatives: _alternatives,
                      selectedIndex: _selectedAlternative!,
                      onSelected: (index) =>
                          _selectAlternative(index, calculation),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      child:
                          ValueListenableBuilder<List<RouteIncidentAnalysis>>(
                            valueListenable: _incidentAnalyses,
                            builder: (context, analyses, _) =>
                                RouteIncidentStatus(
                                  analysis: analyses.isEmpty
                                      ? null
                                      : analyses[_selectedAlternative!],
                                ),
                          ),
                    ),
                    if (_recommendationNotice != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_recommendationNotice!),
                      ),
                  ] else ...[
                    if (_recommendationNotice != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(_recommendationNotice!),
                        ),
                      ),
                    if (hasGps)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tu ubicación actual',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: _checking
                                  ? null
                                  : () => setState(() {
                                      _invalidate();
                                      _manualOrigin = true;
                                    }),
                              child: const Text('Cambiar'),
                            ),
                          ],
                        ),
                      )
                    else if (_manualOrigin && widget.currentPosition != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _invalidate();
                            _manualOrigin = false;
                          }),
                          child: const Text('Usar mi ubicación'),
                        ),
                      ),
                    if (!hasGps && widget.currentPosition == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Semantics(
                          liveRegion: true,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ubicación no disponible. Puedes escribir un origen.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¿A dónde vas?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    RoutePlannerForm(
                      // Destination comes first; origin is requested only when
                      // GPS is unavailable or the user explicitly changes it.
                      title: '¿A dónde vas?',
                      planningOptions: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _planningOptions(),
                      ),
                      embedded: true,
                      compact: true,
                      originController: _origin,
                      destinationController: _destination,
                      onCalculate: _calculate,
                      actionLabel: 'Analizar rutas',
                      isLoading: _checking,
                      originError: _originError,
                      destinationError: _destinationError,
                      showOrigin: !hasGps,
                      originSuggestions: _addressResults(
                        origin: true,
                        child: _loadingOriginSuggestions
                            ? _searchingPlaces()
                            : _originSuggestionError != null
                            ? _assistiveError(_originSuggestionError!)
                            : _originPlaces.isEmpty
                            ? _emptySuggestions(_origin.text, _selectedOrigin)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _originPlaces
                                    .map(
                                      (place) => ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.place_outlined,
                                        ),
                                        title: Text(place.name),
                                        subtitle:
                                            place.description.isEmpty &&
                                                place.precision == null
                                            ? null
                                            : Text(
                                                [
                                                      place.description,
                                                      if (place.precision !=
                                                          null)
                                                        place.precision!.label,
                                                    ]
                                                    .where((s) => s.isNotEmpty)
                                                    .join('\n'),
                                              ),
                                        onTap: () => _selectOrigin(place),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      destinationSuggestions: _addressResults(
                        origin: false,
                        child: _loadingSuggestions
                            ? _searchingPlaces()
                            : _suggestionError != null
                            ? _assistiveError(_suggestionError!)
                            : _places.isEmpty
                            ? _emptySuggestions(_destination.text, _selected)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _places
                                    .map(
                                      (place) => ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.place_outlined,
                                        ),
                                        title: Text(place.name),
                                        subtitle:
                                            place.description.isEmpty &&
                                                place.precision == null
                                            ? null
                                            : Text(
                                                [
                                                      place.description,
                                                      if (place.precision !=
                                                          null)
                                                        place.precision!.label,
                                                    ]
                                                    .where((s) => s.isNotEmpty)
                                                    .join('\n'),
                                              ),
                                        onTap: () => _select(place),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                    if (_phase != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(_phase!),
                      ),
                    if (widget.locationStatus !=
                            LocationStatus.coordinatesObtained &&
                        !_manualOrigin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          'Puedes indicar el origen manualmente.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
