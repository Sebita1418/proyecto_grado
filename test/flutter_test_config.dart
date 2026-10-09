import 'dart:async';

import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

import 'support/boundary_fixtures.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Existing suites test routing/UI with arbitrary coordinates, not municipal
  // membership. Territorial tests explicitly inject their own real/synthetic
  // service, independently of this fixture.
  MunicipalBoundaryService.shared = legacyTestBoundary();
  await testMain();
}
