import 'package:flutter/material.dart';
import '../../../../shared/widgets/mapo_logo.dart';

class AuthLinkErrorPage extends StatelessWidget {
  const AuthLinkErrorPage({
    super.key,
    required this.message,
    required this.onContinue,
  });
  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: MapoLogo(symbolOnly: true, width: 76)),
                const SizedBox(height: 28),
                Text(
                  'Volvamos a tu cuenta',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(message, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: onContinue,
                  child: const Text('Continuar en MAPO'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
