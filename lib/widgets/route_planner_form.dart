import 'package:flutter/material.dart';

class RoutePlannerForm extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onCalculate;
  final bool isLoading;

  final String? originError;
  final String? destinationError;
  final Widget? originSuggestions;
  final Widget? destinationSuggestions;

  const RoutePlannerForm({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.onCalculate,
    this.isLoading = false,
    this.originError,
    this.destinationError,
    this.originSuggestions,
    this.destinationSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Planifica tu ruta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: originController,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Origen',
                hintText: 'Ingresa el punto de origen',
                prefixIcon: const Icon(Icons.trip_origin),
                border: const OutlineInputBorder(),
                errorText: originError,
              ),
            ),

            ?originSuggestions,

            const SizedBox(height: 12),

            TextField(
              controller: destinationController,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Destino',
                hintText: 'Ingresa el punto de destino',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
                errorText: destinationError,
              ),
              onSubmitted: (_) {
                if (!isLoading) {
                  onCalculate();
                }
              },
            ),

            ?destinationSuggestions,

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: isLoading ? null : onCalculate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.route),
              label: Text(isLoading ? 'Calculando...' : 'Calcular ruta'),
            ),
          ],
        ),
      ),
    );
  }
}
