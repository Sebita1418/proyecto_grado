/// Small query-only normalization. The text entered in the UI is untouched.
class AddressQuery {
  static const _roads = {
    'cra': 'Carrera',
    'cr': 'Carrera',
    'carrera': 'Carrera',
    'cl': 'Calle',
    'calle': 'Calle',
    'av': 'Avenida',
    'avenida': 'Avenida',
    'diag': 'Diagonal',
    'diagonal': 'Diagonal',
    'trans': 'Transversal',
    'transversal': 'Transversal',
  };

  static String normalize(String input) => input
      .trim()
      .replaceAllMapped(
        RegExp(
          r'\b(carrera|cra|cr|calle|cl|avenida|av|diagonal|diag|transversal|trans)\.?\s+(?=\d)',
          caseSensitive: false,
        ),
        (match) => '${_roads[match[1]!.toLowerCase()]} ',
      )
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool isAddress(String input) => RegExp(
    r'^(Carrera|Calle|Avenida|Diagonal|Transversal)\s+\d',
    caseSensitive: false,
  ).hasMatch(normalize(input));

  static String forProvider(String input) {
    final normalized = normalize(input);
    if (!isAddress(normalized)) return normalized;
    // Add project context only when the whole query is a numbered address.
    // Any city/neighbourhood text (including cities outside Santander) survives.
    final addressOnly = RegExp(
      r'^(?:(?:Carrera|Calle|Avenida|Diagonal|Transversal)\s+\d+[a-z]?(?:\s+bis)?(?:\s+(?:sur|norte|este|oeste))?\s*(?:#\s*\d+[a-z]?\s*-\s*\d+[a-z]?)?\s*(?:con\s+|y\s+)?)+$',
      caseSensitive: false,
    ).hasMatch(normalized);
    return addressOnly ? '$normalized, Bucaramanga, Colombia' : normalized;
  }
}
