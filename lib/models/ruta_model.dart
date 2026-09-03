class Ruta {
  final String id;
  final String nombre;
  final String origen;
  final String destino;
  final String? descripcion;
  final bool activa;
  final DateTime? fechaCreacion;

  Ruta({
    required this.id,
    required this.nombre,
    required this.origen,
    required this.destino,
    this.descripcion,
    required this.activa,
    this.fechaCreacion,
  });

  factory Ruta.fromMap(Map<String, dynamic> map) {
    return Ruta(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      origen: map['origen'] as String,
      destino: map['destino'] as String,
      descripcion: map['descripcion'] as String?,
      activa: map['activa'] as bool? ?? true,
      fechaCreacion: map['fecha_creacion'] != null
          ? DateTime.tryParse(
              map['fecha_creacion'].toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'origen': origen,
      'destino': destino,
      'descripcion': descripcion,
      'activa': activa,
    };
  }
}