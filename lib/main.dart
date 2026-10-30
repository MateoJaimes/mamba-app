import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      authOptions: FlutterAuthClientOptions(
        localStorage: secureStorage,
        pkceAsyncStorage: secureStorage,
      ),
    );
  }

  runApp(
    ProviderScope(
      child: MambaApp(
        authConfigured: authConfigured,
        // Development can still preview the current prototype before Supabase
        // is configured. Release builds fail closed behind the setup screen.
        authRequired: authConfigured || kReleaseMode,
      ),
    ),
  );
}
