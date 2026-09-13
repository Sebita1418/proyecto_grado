import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/ruta_model.dart';
import '../../services/ruta_service.dart';
import '../../widgets/route_map.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final RutaService _rutaService = RutaService();

  static const LatLng _initialMapPosition = LatLng(4.7110, -74.0721);

  bool cargando = true;
  String? error;

  List<Ruta> rutas = [];
  List<Ruta> rutasFiltradas = [];

  final TextEditingController buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();

    cargarRutas();

    buscarController.addListener(filtrarRutas);
  }

  Future<void> cargarRutas() async {
    try {
      final resultado = await _rutaService.obtenerRutasActivas();

      if (!mounted) return;

      setState(() {
        rutas = resultado;
        rutasFiltradas = resultado;
        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        cargando = false;
      });
    }
  }

  void filtrarRutas() {
    final texto = buscarController.text.trim().toLowerCase();

    setState(() {
      if (texto.isEmpty) {
        rutasFiltradas = List<Ruta>.from(rutas);

        return;
      }

      rutasFiltradas = rutas.where((ruta) {
        final nombre = ruta.nombre.toLowerCase();

        final origen = ruta.origen.toLowerCase();

        final destino = ruta.destino.toLowerCase();

        final descripcion = ruta.descripcion?.toLowerCase() ?? '';

        return nombre.contains(texto) ||
            origen.contains(texto) ||
            destino.contains(texto) ||
            descripcion.contains(texto);
      }).toList();
    });
  }

  Future<void> refrescar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    await cargarRutas();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas disponibles'), centerTitle: true),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _construirError()
          : _construirContenido(),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'No fue posible cargar las rutas.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: refrescar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    return RefreshIndicator(
      onRefresh: refrescar,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Consulta de rutas',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Encuentra una ruta por nombre, origen o destino.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mapa de ruta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const RouteMap(initialPosition: _initialMapPosition),
          const SizedBox(height: 8),
          Text(
            'La ruta calculada se mostrará aquí cuando se complete '
            'la integración con el servicio de rutas.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: buscarController,
            decoration: InputDecoration(
              hintText: 'Buscar ruta...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: buscarController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        buscarController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${rutasFiltradas.length} ruta(s) disponible(s)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (rutasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.route_outlined, size: 65, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay rutas disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            ...rutasFiltradas.map(
              (ruta) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RutaCard(ruta: ruta),
              ),
            ),
        ],
      ),
    );
  }
}

class _RutaCard extends StatelessWidget {
  final Ruta ruta;

  const _RutaCard({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 27,
              child: Icon(Icons.directions_bus_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Origen: ${ruta.origen}'),
                  const SizedBox(height: 6),
                  Text('Destino: ${ruta.destino}'),
                  if (ruta.descripcion != null &&
                      ruta.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      ruta.descripcion!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
