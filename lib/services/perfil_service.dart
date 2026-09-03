import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil_model.dart';

class PerfilService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<Perfil> obtenerPerfilActual() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception(
        'No existe un usuario autenticado.',
      );
    }

    final datos = await _supabase
        .from('perfiles')
        .select()
        .eq('id', usuario.id)
        .single();

    return Perfil.fromMap(datos);
  }

  Future<List<Perfil>> obtenerPerfiles() async {
    final datos = await _supabase
        .from('perfiles')
        .select()
        .order('nombre');

    return (datos as List)
        .map(
          (item) => Perfil.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
  }) async {
    final session =
        _supabase.auth.currentSession;

    if (session == null) {
      throw Exception(
        'No hay una sesión activa.',
      );
    }

    final response =
        await _supabase.functions.invoke(
      'crear-usuario',
      body: {
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'password': password,
        'rol': rol,
      },
      headers: {
        'Authorization':
            'Bearer ${session.accessToken}',
      },
    );

    if (response.status != 200) {
      final data = response.data;

      if (data is Map &&
          data['error'] != null) {
        throw Exception(
          data['error'].toString(),
        );
      }

      throw Exception(
        'No fue posible crear el usuario.',
      );
    }
  }

  Future<void> actualizarEstadoUsuario({
    required String id,
    required bool activo,
  }) async {
    await _supabase
        .from('perfiles')
        .update({
          'activo': activo,
        })
        .eq('id', id);
  }

  Future<void> actualizarRolUsuario({
    required String id,
    required String rol,
  }) async {
    if (
        rol != 'usuario' &&
        rol != 'administrador') {
      throw Exception(
        'El rol seleccionado no es válido.',
      );
    }

    await _supabase
        .from('perfiles')
        .update({
          'rol': rol,
        })
        .eq('id', id);
  }

  String? obtenerIdUsuarioActual() {
    return _supabase.auth.currentUser?.id;
  }
}