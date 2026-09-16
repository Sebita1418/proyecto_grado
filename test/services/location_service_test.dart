import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/location_service.dart';

class FakeLocationGateway implements LocationGateway {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  bool fail = false;
  LatLng point = const LatLng(7.1, -73.1);
  @override
  Future<bool> isServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<LatLng> getPosition() async {
    if (fail) throw StateError('GPS error');
    return point;
  }
}

void main() {
  test('obtiene coordenadas reales del gateway', () async {
    final result = await LocationService(gateway: FakeLocationGateway())
        .locate();
    expect(result.status, LocationStatus.coordinatesObtained);
    expect(result.coordinates, const LatLng(7.1, -73.1));
  });
  test('informa permiso denegado', () async {
    final gateway = FakeLocationGateway()
      ..permission = LocationPermission.denied;
    expect(
      (await LocationService(gateway: gateway).locate()).status,
      LocationStatus.permissionDenied,
    );
  });
  test('informa servicio deshabilitado', () async {
    final gateway = FakeLocationGateway()..enabled = false;
    expect(
      (await LocationService(gateway: gateway).locate()).status,
      LocationStatus.serviceDisabled,
    );
  });
  test('captura errores inesperados', () async {
    final gateway = FakeLocationGateway()..fail = true;
    expect(
      (await LocationService(gateway: gateway).locate()).status,
      LocationStatus.unexpectedError,
    );
  });
}
