import 'package:flutter/material.dart';
import '../constants/env.dart';
import '../services/account_session.dart';

class AccountDestination extends StatelessWidget {
  const AccountDestination({
    super.key,
    required this.tourist,
    required this.host,
  });
  final Widget tourist, host;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AccountSession.instance,
    builder: (context, _) {
      final session = AccountSession.instance;
      if (AppEnvironment.hasSupabaseConfig && session.account == null) {
        if (session.error != null) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: session.refresh,
                child: const Text('Reintentar cargar mi cuenta'),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return session.isHost ? host : tourist;
    },
  );
}
