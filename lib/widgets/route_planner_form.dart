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
  final bool showOrigin;
  final String title;
  final bool embedded;
  final String actionLabel;
  final String loadingLabel;
  final bool compact;
  final Widget? planningOptions;

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
    this.showOrigin = true,
    this.title = 'Planifica tu ruta',
    this.embedded = false,
    this.actionLabel = 'Calcular ruta',
    this.loadingLabel = 'Calculando...',
    this.compact = false,
    this.planningOptions,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          if (!compact) const SizedBox(height: 16),

          if (showOrigin)
            TextField(
              controller: originController,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Origen',
                hintText: 'Busca un lugar o dirección',
                prefixIcon: const Icon(Icons.trip_origin),
                errorText: originError,
              ),
            ),

          if (showOrigin) ?originSuggestions,

          if (showOrigin) const SizedBox(height: 12),

          TextField(
            controller: destinationController,
            autofillHints: const [AutofillHints.fullStreetAddress],
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Destino',
              hintText: 'Busca un lugar o dirección',
              prefixIcon: const Icon(Icons.location_on_outlined),
              errorText: destinationError,
            ),
            onSubmitted: (_) {
              if (!isLoading) {
                onCalculate();
              }
            },
          ),

          ?destinationSuggestions,

          ?planningOptions,

          const SizedBox(height: 16),

          Semantics(
            button: true,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onCalculate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.route_outlined),
              label: Text(isLoading ? loadingLabel : actionLabel),
            ),
          ),
        ],
      ),
    );
    return embedded ? content : Card(child: content);
  }
}
