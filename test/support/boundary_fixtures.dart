import 'dart:convert';

import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

/// Synthetic rectangle for legacy tests of non-geographic behavior. Never
/// shipped as an asset or used as evidence about the actual municipality.
MunicipalBoundaryService legacyTestBoundary() =>
    rectangularBoundary(-100, -89, 20, 89);

MunicipalBoundaryService rectangularBoundary(
  double west,
  double south,
  double east,
  double north,
) => MunicipalBoundaryService.fromGeoJson(
  jsonEncode({
    'type': 'Polygon',
    'coordinates': [
      [
        [west, south],
        [east, south],
        [east, north],
        [west, north],
        [west, south],
      ],
    ],
  }),
);
