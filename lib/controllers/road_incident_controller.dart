import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/incident_report_draft.dart';
import '../models/road_incident_report.dart';
import '../services/road_incident_service.dart';

class RoadIncidentController extends ChangeNotifier {
  RoadIncidentController(this.service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final RoadIncidentService service;
  final DateTime Function() _now;
  List<RoadIncidentReport> reports = [];
  bool ready = false, loading = false;
  String? error;
  bool _disposed = false, _refreshAgain = false, _publishing = false;
  int _revision = 0;
  bool get publishing => _publishing;
  Timer? _debounce, _expiry;
  StreamSubscription<void>? _subscription;

  Future<void> refresh() async {
    if (_disposed) return;
    if (loading) {
      _refreshAgain = true;
      return;
    }
    loading = true;
    notifyListeners();
    final revision = _revision;
    try {
      final result = await service.fetchActiveReports();
      if (_disposed) return;
      if (revision == _revision) {
        reports = _activeUnique(result);
      } else {
        _refreshAgain = true;
      }
      ready = true;
      error = null;
      _subscription ??= service.watchChanges().listen(
        (_) {
          if (_disposed) return;
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), refresh);
        },
        onError: (Object _) {
          if (_disposed) return;
          error = 'Actualización en vivo no disponible. Puedes actualizar reportes.';
          notifyListeners();
        },
      );
      _expiry ??= Timer.periodic(const Duration(minutes: 1), (_) {
        if (_disposed) return;
        final active = reports
            .where((r) => r.isActiveAt(_now().toUtc()))
            .toList();
        if (active.length != reports.length) {
          reports = active;
          notifyListeners();
        }
      });
    } catch (_) {
      if (_disposed) return;
      error = 'No fue posible cargar reportes. Toca para reintentar.';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
        if (_refreshAgain) {
          _refreshAgain = false;
          unawaited(refresh());
        }
      }
    }
  }

  Future<void> publish(IncidentReportDraft draft) async {
    if (_publishing || _disposed) throw StateError('Publicación en curso');
    _publishing = true;
    try {
      final report = await service.createReport(draft);
      if (_disposed) return;
      ++_revision;
      reports = _activeUnique([
        report,
        ...reports.where((r) => r.id != report.id),
      ]);
      notifyListeners();
    } finally {
      _publishing = false;
    }
  }

  List<RoadIncidentReport> _activeUnique(List<RoadIncidentReport> values) {
    final now = _now().toUtc();
    final unique = <String, RoadIncidentReport>{};
    for (final report in values) {
      if (report.isActiveAt(now)) unique.putIfAbsent(report.id, () => report);
    }
    return unique.values.take(100).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _expiry?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
