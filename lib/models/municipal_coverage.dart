enum MunicipalCoverage { inside, outside, unknown }

class MunicipalTerritory {
  const MunicipalTerritory({
    required this.code,
    required this.name,
    required this.assetPath,
  });
  final String code, name, assetPath;
}

class CoverageAssessment {
  const CoverageAssessment(
    this.coverage, {
    this.invalidCoordinates = false,
    this.municipalities = const [],
    this.coverageName = 'Bucaramanga, Girón y Floridablanca',
  });
  final MunicipalCoverage coverage;
  final bool invalidCoordinates;
  final List<MunicipalTerritory> municipalities;
  final String coverageName;
  String? get municipalityCode =>
      municipalities.isEmpty ? null : municipalities.first.code;
  String? get municipalityName =>
      municipalities.isEmpty ? null : municipalities.first.name;
  bool get permitted =>
      coverage == MunicipalCoverage.inside && !invalidCoordinates;
  String get label => invalidCoordinates
      ? 'Coordenadas inválidas'
      : switch (coverage) {
          MunicipalCoverage.inside =>
            municipalities.isEmpty
                ? 'Dentro de la cobertura'
                : 'Dentro de la cobertura · ${municipalities.map((m) => m.name).join(' / ')}',
          MunicipalCoverage.outside => 'Fuera de la cobertura',
          MunicipalCoverage.unknown => 'Cobertura sin verificar',
        };
  String message(String endpoint) => invalidCoordinates
      ? '$endpoint tiene coordenadas inválidas. Elige otro punto.'
      : coverage == MunicipalCoverage.outside
      ? '$endpoint está fuera de la cobertura ($coverageName). Elige otro punto.'
      : 'No se pudo verificar ${endpoint.toLowerCase()}. Reintenta cargar la cobertura territorial.';
}
