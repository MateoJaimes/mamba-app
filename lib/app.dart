import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routes/app_router.dart';
import 'core/routes/route_guards.dart';
import 'core/theme/app_theme.dart';

class MambaApp extends StatefulWidget {
  const MambaApp({
    super.key,
    required this.authConfigured,
    required this.authRequired,
  });

  final bool authConfigured;
  final bool authRequired;

  @override
  State<MambaApp> createState() => _MambaAppState();
}

class _MambaAppState extends State<MambaApp> {
  late final AuthRouterRefresh? _authRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRefresh = widget.authConfigured
        ? AuthRouterRefresh(Supabase.instance.client.auth.onAuthStateChange)
        : null;
    _router = createAppRouter(
      authConfigured: widget.authConfigured,
      authRequired: widget.authRequired,
      authRefresh: _authRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MAMBA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _authRefresh?.dispose();
    super.dispose();
  }
}
