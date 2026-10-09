import 'address_precision.dart';
import 'municipal_coverage.dart';

class GeocodingResult implements AddressCandidate {
  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.road,
    this.houseNumber,
    this.city,
    this.precision,
    this.coverage = const CoverageAssessment(MunicipalCoverage.unknown),
  });

  @override
  final double latitude;
  @override
  final double longitude;
  final String displayName;
  final CoverageAssessment coverage;
  @override
  final String? road;
  @override
  final String? houseNumber;
  @override
  final String? city;
  final AddressPrecision? precision;
}
