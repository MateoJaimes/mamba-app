import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/env.dart';
import 'core/services/supabase_secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authConfigured = AppEnvironment.hasSupabaseConfig;
  if (authConfigured) {
    final secureStorage = SupabaseSecureStorage(
      projectHost: Uri.parse(AppEnvironment.supabaseUrl).host,
    );
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.supabasePublishableKey,
      httpClient: _GatewayHttpClient(),
      authOptions: FlutterAuthClientOptions(
        localStorage: secureStorage,
        pkceAsyncStorage: secureStorage,
      ),
    );
  }

  runApp(
    ProviderScope(
      child: MapoApp(
        authConfigured: authConfigured,
        // Development can still preview the current prototype before Supabase
        // is configured. Release builds fail closed behind the setup screen.
        authRequired: authConfigured || kReleaseMode,
      ),
    ),
  );
}

/// The gateway supplies the provider key. Forward bearer tokens only for users.
class _GatewayHttpClient extends http.BaseClient {
  final _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.headers['authorization'] ==
        'Bearer ${AppEnvironment.supabasePublishableKey}') {
      request.headers.remove('authorization');
    }
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
