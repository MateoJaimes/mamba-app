import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifies GoRouter whenever Supabase changes the active session.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(Stream<AuthState> authEvents) {
    _subscription = authEvents.listen((state) {
      _isPasswordRecovery = state.event == AuthChangeEvent.passwordRecovery;
      if (!_disposed) notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;
  bool _isPasswordRecovery = false;
  bool _disposed = false;

  bool get isPasswordRecovery => _isPasswordRecovery;

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
