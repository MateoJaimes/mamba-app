import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routes/app_router.dart';
import 'core/routes/route_guards.dart';
import 'core/theme/app_theme.dart';
import 'core/services/currency_service.dart';
import 'core/services/account_session.dart';

class MapoApp extends StatefulWidget {
  const MapoApp({
    super.key,
    required this.authConfigured,
    required this.authRequired,
  });

  final bool authConfigured;
  final bool authRequired;

  @override
  State<MapoApp> createState() => _MapoAppState();
}

class _MapoAppState extends State<MapoApp> {
  late final AuthRouterRefresh? _authRefresh;
  late final GoRouter _router;
  StreamSubscription<AuthState>? _currencySubscription;

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
    if (widget.authConfigured) {
      CurrencyService.instance.load();
      AccountSession.instance.refresh();
      _currencySubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(
            (_) {
              CurrencyService.instance.load();
              AccountSession.instance.refresh();
            },
            onError: (Object error, StackTrace stackTrace) {
              // AuthRouterRefresh presents a recoverable account screen.
            },
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MAPO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _currencySubscription?.cancel();
    _router.dispose();
    _authRefresh?.dispose();
    super.dispose();
  }
}
