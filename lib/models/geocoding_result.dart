import 'address_precision.dart';

class GeocodingResult implements AddressCandidate {
  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.road,
    this.houseNumber,
    this.city,
    this.precision,
  });

  @override
  final double latitude;
  @override
  final double longitude;
  final String displayName;
  @override
  final String? road;
  @override
  final String? houseNumber;
  @override
  final String? city;
  final AddressPrecision? precision;
}
