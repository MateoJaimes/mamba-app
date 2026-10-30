import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';
import '../auth/account_access.dart';

/// Authentication adapter. User metadata is profile data only and must never
/// be used for authorization; roles belong in trusted server-side app metadata.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    required AccountIntent intent,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: AppEnvironment.authRedirectUri,
      // This is only the user's requested onboarding path, never an access role.
      data: {'display_name': displayName.trim(), 'account_intent': intent.name},
    );
  }

  Future<void> sendPasswordRecovery(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppEnvironment.authRedirectUri,
    );
  }

  Future<void> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _client.auth.signOut();
}
