import 'package:flutter/foundation.dart';

/// Public client configuration supplied at build/run time.
/// Never put a Supabase secret or service-role key in the app.
abstract final class AppEnvironment {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const authRedirectUri = 'mamba://auth-callback';

  static bool get hasSupabaseConfig {
    final uri = Uri.tryParse(supabaseUrl);
    final hasValidScheme =
        uri != null &&
        (uri.scheme == 'https' || (kDebugMode && uri.scheme == 'http'));

    return hasValidScheme &&
        uri.host.isNotEmpty &&
        supabasePublishableKey.startsWith('sb_publishable_');
  }
}
