import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_suggestion.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/place_suggestion_service.dart';
import 'route_planner_form.dart';

class MapSearchPanel extends StatefulWidget {
  const MapSearchPanel({
    super.key,
    required this.currentPosition,
    required this.locationStatus,
    this.geocodingService,
    this.placeSuggestionService,
  });
  final LatLng? currentPosition;
  final LocationStatus locationStatus;
  final GeocodingService? geocodingService;
  final PlaceSuggestionService? placeSuggestionService;
  @override
  State<MapSearchPanel> createState() => _MapSearchPanelState();
}

class _MapSearchPanelState extends State<MapSearchPanel> {
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  late final _geocoding = widget.geocodingService ?? GeocodingService();
  late final _suggestions =
      widget.placeSuggestionService ?? PlaceSuggestionService();
  Timer? _debounce;
  int _request = 0;
  bool _manualOrigin = false;
  bool _loadingSuggestions = false;
  bool _checking = false;
  String? _suggestionError;
  String? _originError;
  String? _destinationError;
  List<PlaceSuggestion> _places = [];
  PlaceSuggestion? _selected;

  @override
  void initState() {
    super.initState();
    _destination.addListener(_onDestinationChanged);
  }

  void _onDestinationChanged() {
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
    setState(() => _checking = true);
    try {
      if (!hasGps && await _geocoding.search(originText) == null) {
        throw const GeocodingException('No se encontró el origen.');
      }
      if (_selected == null &&
          await _geocoding.search(destinationText) == null) {
        throw const GeocodingException('No se encontró el destino.');
      }
      if (!mounted) return;
      _message(
        'Origen y destino encontrados. El cálculo de ruta estará disponible próximamente.',
      );
    } on GeocodingException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('No fue posible verificar los lugares. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  @override
  void dispose() {
    _debounce?.cancel();
    ++_request;
    _origin.dispose();
    _destination.dispose();
    if (widget.geocodingService == null) _geocoding.dispose();
    if (widget.placeSuggestionService == null) _suggestions.dispose();
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
              if (hasGps)
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: const Text('Tu ubicación actual'),
                  subtitle: const Text('Origen'),
                  trailing: TextButton(
                    onPressed: () => setState(() => _manualOrigin = true),
                    child: const Text('Cambiar'),
                  ),
                )
              else if (_manualOrigin && widget.currentPosition != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _manualOrigin = false),
                    child: const Text('Usar mi ubicación'),
                  ),
                ),
              RoutePlannerForm(
                originController: _origin,
                destinationController: _destination,
                onCalculate: _calculate,
                isLoading: _checking,
                originError: _originError,
                destinationError: _destinationError,
                showOrigin: !hasGps,
                title: '¿A dónde quieres ir?',
                destinationSuggestions: _loadingSuggestions
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Buscando lugares...'),
                      )
                    : _suggestionError != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_suggestionError!),
                      )
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
              if (widget.locationStatus != LocationStatus.coordinatesObtained &&
                  !_manualOrigin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Puedes indicar el origen manualmente.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
