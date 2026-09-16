import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_suggestion.dart';
import '../models/geocoding_result.dart';
import '../models/route_result.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/place_suggestion_service.dart';
import '../services/osrm_routing_service.dart';
import 'route_planner_form.dart';
import 'route_result_card.dart';

class MapSearchPanel extends StatefulWidget {
  const MapSearchPanel({
    super.key,
    required this.currentPosition,
    required this.locationStatus,
    this.geocodingService,
    this.placeSuggestionService,
    this.routingService,
    this.onRouteChanged,
  });
  final LatLng? currentPosition;
  final LocationStatus locationStatus;
  final GeocodingService? geocodingService;
  final PlaceSuggestionService? placeSuggestionService;
  final OsrmRoutingService? routingService;
  final ValueChanged<RouteResult?>? onRouteChanged;
  @override
  State<MapSearchPanel> createState() => _MapSearchPanelState();
}

class _MapSearchPanelState extends State<MapSearchPanel> {
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  late final _geocoding = widget.geocodingService ?? GeocodingService();
  late final _suggestions =
      widget.placeSuggestionService ?? PlaceSuggestionService();
  late final _routing = widget.routingService ?? OsrmRoutingService();
  Timer? _debounce;
  Timer? _originDebounce;
  int _request = 0;
  int _originRequest = 0;
  bool _manualOrigin = false;
  bool _loadingSuggestions = false;
  bool _loadingOriginSuggestions = false;
  bool _checking = false;
  String? _phase;
  RouteResult? _route;
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

  @override
  void didUpdateWidget(covariant MapSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition) {
      ++_calculation;
      _checking = false;
      _phase = null;
      _route = null;
      _showEditor = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRouteChanged?.call(null);
      });
    }
  }

  void _invalidate() {
    ++_calculation;
    _checking = false;
    _phase = null;
    if (_route != null) {
      _route = null;
      _showEditor = true;
      widget.onRouteChanged?.call(null);
    }
  }

  @override
  void initState() {
    super.initState();
    _destination.addListener(_onDestinationChanged);
    _origin.addListener(_onOriginChanged);
  }

  void _onOriginChanged() {
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
    setState(() {
      _checking = true;
      _phase = 'Buscando lugares...';
      _route = null;
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
      final result = await _routing
          .route(origin: origin, destination: destination)
          .timeout(const Duration(seconds: 20));
      if (!mounted || calculation != _calculation) return;
      setState(() {
        _route = result;
        _showEditor = false;
        _routeOriginLabel = hasGps ? 'Tu ubicación actual' : originText;
        _routeDestinationLabel = _selected?.name ?? destinationText;
      });
      widget.onRouteChanged?.call(result);
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * .58),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_route != null && !_showEditor)
                RouteResultCard(
                  route: _route!,
                  originLabel: _routeOriginLabel,
                  destinationLabel: _routeDestinationLabel,
                  onModify: () => setState(() => _showEditor = true),
                )
              else ...[
                if (hasGps)
                  ListTile(
                    leading: const Icon(Icons.my_location),
                    title: const Text('Tu ubicación actual'),
                    subtitle: const Text('Origen'),
                    trailing: TextButton(
                      onPressed: () => setState(() {
                        _invalidate();
                        _manualOrigin = true;
                      }),
                      child: const Text('Cambiar'),
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
                    padding: const EdgeInsets.only(bottom: 8),
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
