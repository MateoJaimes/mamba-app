import 'package:flutter/foundation.dart';

/// Public client configuration supplied at build/run time.
/// Never put a Supabase secret or service-role key in the app.
abstract final class AppEnvironment {
  // The APK only knows the NestJS API. Supabase credentials live on the server.
  static const supabaseUrl = String.fromEnvironment('API_BASE_URL');
  static const supabasePublishableKey = 'sb_publishable_mamba_frontend';
  static const authRedirectUri =
      'https://mapo-experiencias-api.vercel.app/auth/callback';
  static const mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

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
