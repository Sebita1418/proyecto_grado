import 'address_precision.dart';
import 'municipal_coverage.dart';

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
    this.coverage = const CoverageAssessment(MunicipalCoverage.unknown),
  });

  final String name;
  final CoverageAssessment coverage;
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
