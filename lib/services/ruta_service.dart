import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ruta_model.dart';

class RutaService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<Ruta>> obtenerRutas() async {
    final datos = await _supabase
        .from('rutas')
        .select()
        .order('nombre');

    return (datos as List)
        .map(
          (item) => Ruta.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<Ruta>> obtenerRutasActivas() async {
    final datos = await _supabase
        .from('rutas')
        .select()
        .eq('activa', true)
        .order('nombre');

    return (datos as List)
        .map(
          (item) => Ruta.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> crearRuta({
    required String nombre,
    required String origen,
    required String destino,
    String? descripcion,
  }) async {
    final nombreLimpio = nombre.trim();
    final origenLimpio = origen.trim();
    final destinoLimpio = destino.trim();
    final descripcionLimpia =
        descripcion?.trim();

    if (nombreLimpio.isEmpty ||
        origenLimpio.isEmpty ||
        destinoLimpio.isEmpty) {
      throw Exception(
        'Nombre, origen y destino son obligatorios.',
      );
    }

    await _supabase.from('rutas').insert({
      'nombre': nombreLimpio,
      'origen': origenLimpio,
      'destino': destinoLimpio,
      'descripcion':
          descripcionLimpia == null ||
                  descripcionLimpia.isEmpty
              ? null
              : descripcionLimpia,
      'activa': true,
    });
  }

  Future<void> actualizarRuta({
    required String id,
    required String nombre,
    required String origen,
    required String destino,
    String? descripcion,
  }) async {
    final nombreLimpio = nombre.trim();
    final origenLimpio = origen.trim();
    final destinoLimpio = destino.trim();
    final descripcionLimpia =
        descripcion?.trim();

    if (nombreLimpio.isEmpty ||
        origenLimpio.isEmpty ||
        destinoLimpio.isEmpty) {
      throw Exception(
        'Nombre, origen y destino son obligatorios.',
      );
    }

    await _supabase
        .from('rutas')
        .update({
          'nombre': nombreLimpio,
          'origen': origenLimpio,
          'destino': destinoLimpio,
          'descripcion':
              descripcionLimpia == null ||
                      descripcionLimpia.isEmpty
                  ? null
                  : descripcionLimpia,
        })
        .eq('id', id);
  }

  Future<void> cambiarEstadoRuta({
    required String id,
    required bool activa,
  }) async {
    await _supabase
        .from('rutas')
        .update({
          'activa': activa,
        })
        .eq('id', id);
  }

  Future<Ruta> obtenerRutaPorId(
    String id,
  ) async {
    final datos = await _supabase
        .from('rutas')
        .select()
        .eq('id', id)
        .single();

    return Ruta.fromMap(datos);
  }
}