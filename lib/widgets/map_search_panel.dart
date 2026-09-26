import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../mobility/mobility_context.dart';
import '../mobility/mobility_recommendation.dart';
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

class MapSearchPanel extends StatefulWidget {
  const MapSearchPanel({
    super.key,
    required this.currentPosition,
    required this.locationStatus,
    this.geocodingService,
    this.placeSuggestionService,
    this.routingService,
    this.onRouteChanged,
    this.preferencesService = const MobilityPreferencesService(),
    this.recommendationEngine,
  });
  final LatLng? currentPosition;
  final LocationStatus locationStatus;
  final GeocodingService? geocodingService;
  final PlaceSuggestionService? placeSuggestionService;
  final OsrmRoutingService? routingService;
  final ValueChanged<RouteResult?>? onRouteChanged;
  final MobilityPreferencesService preferencesService;
  final MobilityRecommendationEngine? recommendationEngine;
  @override
  State<MapSearchPanel> createState() => _MapSearchPanelState();
}

class _MapSearchPanelState extends State<MapSearchPanel> {
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
    _alternatives = const [];
    _selectedAlternative = null;
    _recommendation = null;
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
      final recommendation = await _engine.recommend(context, options);
      if (!mounted || calculation != _calculation) return;
      final suggestedIndex = options.indexWhere(
        (option) => option.id == recommendation.recommended.id,
      );
      if (suggestedIndex < 0) throw StateError('Unknown recommended route');
      setState(() {
        _alternatives = List.unmodifiable(results);
        _selectedAlternative = suggestedIndex;
        _suggestedAlternative = suggestedIndex;
        _recommendation = recommendation;
        _usesDefaultModes = usesDefaultModes;
        _showEditor = false;
        _routeOriginLabel = hasGps ? 'Tu ubicación actual' : originText;
        _routeDestinationLabel = _selected?.name ?? destinationText;
      });
      widget.onRouteChanged?.call(_route);
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
              'No hay sugerencias disponibles. Puedes escribir y calcular.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
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
      constraints: BoxConstraints(maxHeight: height * .48),
      child: Material(
        elevation: 8,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (_route != null && !_showEditor) ...[
                RouteResultCard(
                  route: _route!,
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
                  alternatives: _alternatives,
                  selectedIndex: _selectedAlternative!,
                  onSelected: (index) => _selectAlternative(index, calculation),
                ),
                if (_recommendation != null)
                  MobilityRecommendationSummary(
                    compact: true,
                    recommendation: _recommendation!,
                    suggestedIndex: _suggestedAlternative!,
                    selectedIndex: _selectedAlternative!,
                    manuallySelected: _manuallySelected,
                    usesDefaultModes: _usesDefaultModes,
                  ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                  child: TravelModeSelector(
                    compact: true,
                    selectedMode: _selectedMode,
                    onModeSelected: (mode) {
                      if (mode == TransportMode.driving) {
                        setState(() => _selectedMode = mode);
                      }
                    },
                    onUnavailableModeTap: (mode) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'El modo ${mode.label} estará disponible próximamente. '
                            'Actualmente solo se admiten rutas vehiculares.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ),
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
                RoutePlannerForm(
                  embedded: true,
                  compact: true,
                  originController: _origin,
                  destinationController: _destination,
                  onCalculate: _calculate,
                  isLoading: _checking,
                  originError: _originError,
                  destinationError: _destinationError,
                  showOrigin: !hasGps,
                  title: '¿A dónde quieres ir?',
                  originSuggestions: _loadingOriginSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Buscando lugares...'),
                        )
                      : _originSuggestionError != null
                      ? _assistiveError(_originSuggestionError!)
                      : _originPlaces.isEmpty
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _originPlaces
                              .map(
                                (place) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(place.name),
                                  subtitle: place.description.isEmpty
                                      ? null
                                      : Text(place.description),
                                  onTap: () => _selectOrigin(place),
                                ),
                              )
                              .toList(),
                        ),
                  destinationSuggestions: _loadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Buscando lugares...'),
                        )
                      : _suggestionError != null
                      ? _assistiveError(_suggestionError!)
                      : _places.isEmpty
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _places
                              .map(
                                (place) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(place.name),
                                  subtitle: place.description.isEmpty
                                      ? null
                                      : Text(place.description),
                                  onTap: () => _select(place),
                                ),
                              )
                              .toList(),
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
          ),
        ),
      ),
    );
  }
}
