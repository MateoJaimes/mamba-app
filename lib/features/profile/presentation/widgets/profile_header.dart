import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/env.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AppEnvironment.hasSupabaseConfig
        ? Supabase.instance.client.auth.currentUser
        : null;
    final metadataName = user?.userMetadata?['display_name'];
    final displayName = metadataName is String && metadataName.trim().isNotEmpty
        ? metadataName.trim()
        : user?.email?.split('@').first ?? 'Explorador MAMBA';
    final contact = user?.email ?? 'Descubre experiencias a tu manera';

    return Column(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person_outline,
            size: 52,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          contact,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () {}, child: const Text('Editar perfil')),
      ],
    );
  }
}
