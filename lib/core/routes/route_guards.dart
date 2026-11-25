import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifies GoRouter whenever Supabase changes the active session.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(Stream<AuthState> authEvents) {
    _subscription = authEvents.listen(
      (state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecovery = true;
        } else if (state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.userUpdated ||
            state.event == AuthChangeEvent.signedIn) {
          _isPasswordRecovery = false;
        }
        _linkError = null;
        if (!_disposed) notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _linkError =
            'No pudimos completar este enlace. Puede haber vencido, '
            'haberse usado o haberse abierto en otro dispositivo. '
            'Si ya confirmaste tu correo, inicia sesión. '
            'Para recuperar tu contraseña, solicita un correo nuevo desde este celular.';
        if (!_disposed) notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;
  bool _isPasswordRecovery = false;
  bool _disposed = false;
  String? _linkError;

  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get linkError => _linkError;

  void clearLinkError() {
    _linkError = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
