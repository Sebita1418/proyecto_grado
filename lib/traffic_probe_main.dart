// Temporary manual entrypoint. Not imported by the production main.dart.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    debug: false,
  );
  runApp(const MaterialApp(home: TrafficSessionProbe()));
}

class TrafficSessionProbe extends StatefulWidget {
  const TrafficSessionProbe({super.key});
  @override
  State<TrafficSessionProbe> createState() => _TrafficSessionProbeState();
}

class _TrafficSessionProbeState extends State<TrafficSessionProbe> {
  static const enabled = bool.fromEnvironment('TRAFFIC_PROXY_ENABLED');
  bool _verified = false, _attempted = false;
  String _message = 'Comprobando sesión existente, sin iniciar Google OAuth…';
  Map<String, Object?>? _result;

  void _record(Map<String, Object?> data) {
    // Explicit allowlist constructed below. Never stringify sessions, errors or bodies.
    debugPrint('TOMTOM_PROBE_SAFE ${jsonEncode(data)}');
    if (mounted) setState(() => _result = data);
  }

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final client = Supabase.instance.client;
    try {
      var session = client.auth.currentSession;
      if (!enabled || session == null) {
        _record({
          'phase': 'session',
          'sessionPresent': session != null,
          'trafficEnabled': enabled,
          'valid': false,
          'checkedAt': DateTime.now().toUtc().toIso8601String(),
        });
        if (mounted) {
          setState(
            () => _message = 'DETENER: sesión ausente o prueba deshabilitada. No se inicia OAuth.',
          );
        }
        return;
      }
      if (session.isExpired) {
        await client.auth.refreshSession().timeout(const Duration(seconds: 15));
        session = client.auth.currentSession;
      }
      final user = await client.auth.getUser().timeout(
        const Duration(seconds: 15),
      );
      final valid =
          session != null &&
          !session.isExpired &&
          user.user?.id == session.user.id;
      _record({
        'phase': 'session',
        'sessionPresent': session != null,
        'trafficEnabled': enabled,
        'valid': valid,
        'checkedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _verified = valid;
          _message = valid
              ? 'Sesión activa verificada por Supabase Auth. Una sola consulta permitida.'
              : 'DETENER: sesión no válida. No se inicia OAuth.';
        });
      }
    } on Object {
      _record({
        'phase': 'session',
        'valid': false,
        'status': 'AUTH_CHECK_FAILED',
        'checkedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        setState(() => _message = 'DETENER: falló la comprobación de sesión.');
      }
    }
  }

  Future<void> _invokeOnce() async {
    if (!_verified || _attempted || !enabled) return;
    setState(() {
      _attempted = true;
      _message = 'Consultando traffic-flow una vez…';
    });
    final watch = Stopwatch()..start();
    final requestedAt = DateTime.now().toUtc().toIso8601String();
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'traffic-flow',
        body: {'latitude': 7.1196763, 'longitude': -73.1228536},
        abortSignal: Future<void>.delayed(const Duration(seconds: 20)),
      );
      watch.stop();
      final body = response.data is Map ? response.data as Map : const {};
      final flow = body['flowSegmentData'] is Map
          ? body['flowSegmentData'] as Map
          : const {};
      num? value(String name) {
        final item = flow[name];
        return item is num && item.isFinite && item >= 0 ? item : null;
      }

      final timestamp = body['queriedAt'] is String
          ? DateTime.tryParse(body['queriedAt'])
          : null;
      _record({
        'phase': 'traffic',
        'httpStatus': response.status,
        'available':
            response.status == 200 &&
            body['provider'] == 'TomTom' &&
            flow.isNotEmpty,
        'requestedAt': requestedAt,
        'queriedAt': timestamp?.toUtc().toIso8601String(),
        'latencyMilliseconds': watch.elapsedMilliseconds,
        'currentSpeedKmph': value('currentSpeed'),
        'freeFlowSpeedKmph': value('freeFlowSpeed'),
        'currentTravelTimeSeconds': value('currentTravelTime'),
        'freeFlowTravelTimeSeconds': value('freeFlowTravelTime'),
        'confidence': value('confidence'),
      });
    } on FunctionException catch (error) {
      watch.stop();
      _record({
        'phase': 'traffic',
        'httpStatus': error.status,
        'available': false,
        'requestedAt': requestedAt,
        'latencyMilliseconds': watch.elapsedMilliseconds,
      });
    } on Object {
      watch.stop();
      _record({
        'phase': 'traffic',
        'httpStatus': null,
        'available': false,
        'requestedAt': requestedAt,
        'latencyMilliseconds': watch.elapsedMilliseconds,
      });
    }
    if (mounted) {
      setState(
        () => _message = 'Prueba terminada. No se repite automáticamente. No cambia rutas ni ETA.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prueba temporal TomTom')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Diagnóstico manual. No es una nueva entrega académica.'),
          const SizedBox(height: 24),
          Text(_message),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _verified && !_attempted ? _invokeOnce : null,
            child: const Text('Consultar TomTom una vez'),
          ),
          const SizedBox(height: 24),
          if (_result != null)
            Text(const JsonEncoder.withIndent('  ').convert(_result)),
        ],
      ),
    ),
  );
}
