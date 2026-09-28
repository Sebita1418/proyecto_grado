import 'address_precision.dart';

class PlaceSuggestion implements AddressCandidate {
  const PlaceSuggestion({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.precision,
    this.road,
    this.houseNumber,
    this.city,
  });

  final String name;
  final String description;
  @override
  final double latitude;
  @override
  final double longitude;
  final AddressPrecision? precision;
  @override
  final String? road;
  @override
  final String? houseNumber;
  @override
  final String? city;

  String get displayText => description.isEmpty ? name : '$name, $description';
}
