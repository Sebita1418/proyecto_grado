enum AddressPrecision {
  specific('Coincidencia específica'),
  approximate('Numeración no confirmada'),
  poi('Lugar');

  const AddressPrecision(this.label);
  final String label;
}

abstract interface class AddressCandidate {
  String? get road;
  String? get houseNumber;
  String? get city;
  double get latitude;
  double get longitude;
}
