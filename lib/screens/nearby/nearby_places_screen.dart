import 'package:flutter/material.dart';

/// UX / derivado funcional: pendiente de verificación FDC-124.
/// No consulta proveedores. Una futura integración deberá distinguir carga,
/// resultados verificados, búsqueda vacía y error del estado no disponible.
class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  static const _categories = <String, IconData>{
    'Transporte': Icons.directions_bus_outlined,
    'Salud': Icons.local_hospital_outlined,
    'Parqueaderos': Icons.local_parking_outlined,
    'Servicios': Icons.storefront_outlined,
  };
  String _selectedCategory = 'Transporte';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        title: const Text('Puntos cercanos'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.explore_outlined, size: 40, color: colors.primary),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'Explora tu entorno',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige el tipo de lugar que te interesa para tus desplazamientos.',
                  ),
                  const SizedBox(height: 24),
                  Text('Categorías', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in _categories.entries)
                        ChoiceChip(
                          avatar: Icon(category.value, size: 20),
                          label: Text(category.key),
                          selected: _selectedCategory == category.key,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // No fuente disponible no equivale a una búsqueda sin resultados.
                  Card.filled(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: colors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Aún no disponible',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              'Categoría elegida: $_selectedCategory',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Todavía no contamos con información de lugares cercanos. '
                            'Podrás consultarlos aquí cuando esa información esté disponible.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Por ahora, elegir una categoría no realiza una búsqueda.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Volver al mapa'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
