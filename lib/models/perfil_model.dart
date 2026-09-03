class Perfil {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;

  Perfil({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      correo: map['correo'] as String,
      rol: map['rol'] as String,
      activo: map['activo'] as bool,
    );
  }

  bool get esAdministrador => rol == 'administrador';
}