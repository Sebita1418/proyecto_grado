import '../models/address_precision.dart';

import 'package:latlong2/latlong.dart';

/// Query-only normalization. The original text is retained for the UI.
class AddressQuery {
  AddressQuery(String input) : original = input, normalized = normalize(input) {
    final match = RegExp(
      r'^((?:Calle|Carrera|Avenida|Diagonal|Transversal)\s+\d+[a-z]?(?:\s+bis)?(?:\s+(?:sur|norte|este|oeste))?)(?:\s*#?\s*(\d+[a-z]?)\s*[- ]\s*(\d+[a-z]?))?(?:\s+(?:con\s+)?((?:Calle|Carrera|Avenida|Diagonal|Transversal)\s+\d+[a-z]?))?(.*)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    primaryRoad = match?[1];
    secondaryNumber = match?[2];
    propertyNumber = match?[3];
    crossingRoad = match?[4];
    locality = match?[5]?.replaceFirst(RegExp(r'^[,\s]+'), '').trim() ?? '';
  }
  final String original, normalized;
  late final String? primaryRoad, secondaryNumber, propertyNumber, crossingRoad;
  late final String locality;
  bool get hasCity => locality.isNotEmpty;
  String? get houseNumber =>
      secondaryNumber == null ? null : '$secondaryNumber-$propertyNumber';
  static const maxVariants = 3;
  // Demonstration bias only: never coordinates for a resolved destination.
  static const metropolitanBias = LatLng(7.08, -73.10);

  List<T> rank<T extends AddressCandidate>(List<T> values, {LatLng? bias}) {
    if (primaryRoad == null) return values;
    final indexed = values.asMap().entries.toList();
    indexed.sort((a, b) {
      final x = a.value, y = b.value;
      var comparison = compatibility(
        y.road,
        y.houseNumber,
      ).compareTo(compatibility(x.road, x.houseNumber));
      if (comparison != 0) return comparison;
      comparison = (cityMatches(y.city) ? 1 : 0).compareTo(
        cityMatches(x.city) ? 1 : 0,
      );
      if (comparison != 0) return comparison;
      if (!hasCity && bias != null) {
        final distance = const Distance();
        comparison = distance(
          bias,
          LatLng(x.latitude, x.longitude),
        ).compareTo(distance(bias, LatLng(y.latitude, y.longitude)));
        if (comparison != 0) return comparison;
      }
      int completeness(T value) => [
        value.road,
        value.houseNumber,
        value.city,
      ].where((s) => s != null && s.isNotEmpty).length;
      comparison = completeness(y).compareTo(completeness(x));
      return comparison != 0 ? comparison : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  List<String> get variants {
    if (houseNumber == null) return [normalized];
    final suffix = locality.isEmpty ? '' : ', $locality';
    return [
      if (hasCity) '$primaryRoad $houseNumber$suffix',
      '$primaryRoad # $houseNumber$suffix',
      if (!hasCity) '$primaryRoad $houseNumber$suffix',
      '$primaryRoad$suffix',
    ];
  }

  static String comparable(String value) =>
      normalize(value)
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool cityMatches(String? city) =>
      !hasCity ||
      (city != null &&
          comparable(locality.split(',').first) == comparable(city));

  int compatibility(String? road, String? house) {
    if (primaryRoad == null) return 0;
    if (road == null || comparable(road) != comparable(primaryRoad!)) return 0;
    return houseNumber != null &&
            house != null &&
            _houseTokens(house) == _houseTokens(houseNumber!)
        ? 2
        : 1;
  }

  static String _houseTokens(String value) => RegExp(
    r'\d+[a-z]?',
    caseSensitive: false,
  ).allMatches(value).map((m) => m[0]!.toLowerCase()).join('-');

  AddressPrecision precisionFor(String? road, String? house, String? city) =>
      primaryRoad == null
      ? AddressPrecision.poi
      : compatibility(road, house) == 2 &&
            cityMatches(city) &&
            crossingRoad == null
      ? AddressPrecision.specific
      : AddressPrecision.approximate;
  static const _roads = {
    'cra': 'Carrera',
    'cr': 'Carrera',
    'carrera': 'Carrera',
    'cl': 'Calle',
    'calle': 'Calle',
    'av': 'Avenida',
    'avenida': 'Avenida',
    'diag': 'Diagonal',
    'diagonal': 'Diagonal',
    'trans': 'Transversal',
    'transversal': 'Transversal',
  };

  static String normalize(String input) => input
      .trim()
      .replaceAllMapped(
        RegExp(
          r'\b(carrera|cra|cr|calle|cl|avenida|av|diagonal|diag|transversal|trans)\.?\s+(?=\d)',
          caseSensitive: false,
        ),
        (match) => '${_roads[match[1]!.toLowerCase()]} ',
      )
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool isAddress(String input) => RegExp(
    r'^(Carrera|Calle|Avenida|Diagonal|Transversal)\s+\d',
    caseSensitive: false,
  ).hasMatch(normalize(input));

  static String forProvider(String input) {
    final normalized = normalize(input);
    if (!isAddress(normalized)) return normalized;
    return normalized;
  }
}
