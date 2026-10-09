enum MunicipalCoverage { inside, outside, unknown }

class CoverageAssessment {
  const CoverageAssessment(this.coverage, {this.invalidCoordinates = false});
  final MunicipalCoverage coverage;
  final bool invalidCoordinates;
  bool get permitted =>
      coverage == MunicipalCoverage.inside && !invalidCoordinates;
  String get label => invalidCoordinates
      ? 'Coordenadas inválidas'
      : switch (coverage) {
          MunicipalCoverage.inside => 'Dentro de Bucaramanga',
          MunicipalCoverage.outside => 'Fuera de Bucaramanga',
          MunicipalCoverage.unknown => 'Cobertura sin verificar',
        };
  String message(String endpoint) => invalidCoordinates
      ? '$endpoint tiene coordenadas inválidas. Elige otro punto.'
      : coverage == MunicipalCoverage.outside
      ? '$endpoint está fuera de Bucaramanga. Elige otro punto dentro del municipio.'
      : 'No se pudo verificar ${endpoint.toLowerCase()}. Reintenta cargar el límite municipal.';
}
