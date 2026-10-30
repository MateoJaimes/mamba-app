import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/env.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu.dart';
import '../widgets/profile_stats.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _ProfileSettingsButton(),
                  ),
                  const SizedBox(height: 8),
                  const ProfileHeader(),
                  if (AppEnvironment.hasSupabaseConfig) ...[
                    const SizedBox(height: 20),
                    const _SignOutButton(),
                  ],
                  const SizedBox(height: 24),
                  const ProfileStats(),
                  const SizedBox(height: 28),
                  const ProfileMenu(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService(Supabase.instance.client).signOut();
      if (context.mounted) context.go('/auth');
    } on AuthException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar la sesión. Inténtalo de nuevo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _signOut(context),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Cerrar sesión'),
    );
  }
}

class _ProfileSettingsButton extends StatelessWidget {
  const _ProfileSettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Configuración',
    );
  }
}
