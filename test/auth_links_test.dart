import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapo_app/core/routes/route_guards.dart';

void main() {
  test('auth link errors are consumed and can be dismissed safely', () async {
    final stream = StreamController<AuthState>.broadcast();
    final refresh = AuthRouterRefresh(stream.stream);
    stream.addError(const AuthException('expired link'));
    await Future<void>.delayed(Duration.zero);
    expect(refresh.linkError, contains('correo nuevo'));
    refresh.clearLinkError();
    expect(refresh.linkError, isNull);
    refresh.dispose();
    await stream.close();
  });
  test(
    'refreshing tokens does not dismiss password recovery before saving',
    () async {
      final stream = StreamController<AuthState>.broadcast();
      final refresh = AuthRouterRefresh(stream.stream);
      stream.add(AuthState(AuthChangeEvent.passwordRecovery, null));
      await Future<void>.delayed(Duration.zero);
      expect(refresh.isPasswordRecovery, isTrue);
      stream.add(AuthState(AuthChangeEvent.tokenRefreshed, null));
      await Future<void>.delayed(Duration.zero);
      expect(refresh.isPasswordRecovery, isTrue);
      stream.add(AuthState(AuthChangeEvent.userUpdated, null));
      await Future<void>.delayed(Duration.zero);
      expect(refresh.isPasswordRecovery, isFalse);
      refresh.dispose();
      await stream.close();
    },
  );
}
