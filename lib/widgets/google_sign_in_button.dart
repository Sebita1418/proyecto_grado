import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool canPress = enabled && !isLoading && onPressed != null;

    return Semantics(
      button: true,
      enabled: canPress,
      label: isLoading ? 'Iniciando sesión con Google' : 'Continuar con Google',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: canPress ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('G', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Continuar con Google',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
