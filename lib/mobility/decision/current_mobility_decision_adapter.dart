import '../mobility_context.dart';
import '../route_option.dart';
import '../transport_mode.dart';
import 'departure_time_context.dart';
import 'mobility_data_availability.dart';
import 'mobility_decision_context.dart';
import 'mobility_option_availability.dart';

/// Current product capabilities from snapshots already owned by the planner.
class CurrentMobilityDecisionAdapter {
  const CurrentMobilityDecisionAdapter();

  MobilityDecisionContext build({
    required MobilityContext trip,
    required DepartureTimeContext departure,
    required List<RouteOption> routes,
    bool recommendationUnavailable = false,
  }) {
    final drivingRoutes = routes
        .where(
          (r) =>
              r.mode == TransportMode.driving &&
              r.route.origin == trip.origin &&
              r.route.destination == trip.destination,
        )
        .toList();
    final hasRoutes = drivingRoutes.isNotEmpty;
    final hasReports =
        hasRoutes &&
        drivingRoutes.every(
          (r) => trip.incidentAnalyses[r.id]?.routeId == r.id,
        );
    return MobilityDecisionContext(
      mobilityContext: trip,
      departureTime: departure,
      options: [
        for (final mode in trip.allowedModes)
          option(
            mode,
            departure: departure,
            hasLocation: true,
            hasRoutes: hasRoutes,
            hasReports: hasReports,
            recommendationUnavailable: recommendationUnavailable,
          ),
      ],
    );
  }

  MobilityOptionAvailability option(
    TransportMode mode, {
    required DepartureTimeContext departure,
    bool hasLocation = false,
    bool hasRoutes = false,
    bool hasReports = false,
    bool recommendationUnavailable = false,
  }) {
    final driving = mode == TransportMode.driving;
    return MobilityOptionAvailability(
      mode: mode,
      status: !driving
          ? MobilityOptionStatus.unsupported
          : recommendationUnavailable
          ? MobilityOptionStatus.temporarilyUnavailable
          : hasLocation && hasRoutes && departure.isNow
          ? MobilityOptionStatus.evaluable
          : MobilityOptionStatus.insufficientData,
      additionalRequiredData: {
        if (departure.isScheduled) MobilityDataKind.temporal,
      },
      data: MobilityDataAvailability(
        statuses: {
          MobilityDataKind.location: hasLocation
              ? MobilityDataStatus.available
              : MobilityDataStatus.unknown,
          MobilityDataKind.routing: driving && hasRoutes
              ? MobilityDataStatus.available
              : MobilityDataStatus.unavailable,
          MobilityDataKind.durationAndDistance: driving && hasRoutes
              ? MobilityDataStatus.available
              : MobilityDataStatus.unavailable,
          MobilityDataKind.roadConditions: driving && hasReports
              ? MobilityDataStatus.available
              : MobilityDataStatus.unavailable,
          MobilityDataKind.temporal: MobilityDataStatus.unavailable,
          MobilityDataKind.transport: MobilityDataStatus.unavailable,
        },
      ),
    );
  }
}
