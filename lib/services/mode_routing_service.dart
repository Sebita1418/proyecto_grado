import 'package:latlong2/latlong.dart';

import '../config/osrm_config.dart';
import '../models/route_result.dart';
import '../mobility/transport_mode.dart';
import '../mobility/routing/routing_capabilities.dart';
import 'osrm_routing_service.dart';

class RoutingRequest {
  const RoutingRequest({
    required this.origin,
    required this.destination,
    required this.mode,
  });
  final LatLng origin, destination;
  final TransportMode mode;
}

/// Each mode targets its own preprocessed graph, not a renamed car response.
class ModeRoutingService {
  ModeRoutingService({
    required OsrmRoutingService driving,
    OsrmRoutingService? walking,
    OsrmRoutingService? cycling,
    bool enableWalking = true,
    bool enableCycling = true,
  }) : _services = {
         TransportMode.driving: driving,
         if (enableWalking)
           TransportMode.walking:
               walking ??
               OsrmRoutingService(endpoint: OsrmConfig.walkingEndpoint),
         if (enableCycling)
           TransportMode.cycling:
               cycling ??
               OsrmRoutingService(endpoint: OsrmConfig.cyclingEndpoint),
       },
       _ownsWalking = walking == null && enableWalking,
       _ownsCycling = cycling == null && enableCycling;
  final Map<TransportMode, OsrmRoutingService> _services;
  final bool _ownsWalking, _ownsCycling;
  RoutingCapabilities get capabilities => RoutingCapabilities(_services.keys);
  Future<List<RouteResult>> route(RoutingRequest request) {
    final service = _services[request.mode];
    if (service == null) {
      throw const OsrmRoutingException(
        'Sin proveedor integrado para este modo.',
        failure: RoutingFailure.unsupported,
      );
    }
    return service.routeAlternatives(
      origin: request.origin,
      destination: request.destination,
    );
  }

  void dispose() {
    if (_ownsWalking) _services[TransportMode.walking]!.dispose();
    if (_ownsCycling) _services[TransportMode.cycling]!.dispose();
  }
}
