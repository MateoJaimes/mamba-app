import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileMenuItem(
          icon: Icons.favorite_border,
          title: 'Mis favoritos',
          subtitle: 'Experiencias que guardaste',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.rate_review_outlined,
          title: 'Mis reseñas',
          subtitle: 'Reseñas que has publicado',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.notifications_none,
          title: 'Notificaciones',
          subtitle: 'Configura tus notificaciones',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.help_outline,
          title: 'Ayuda',
          subtitle: 'Preguntas frecuentes y soporte',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.info_outline,
          title: 'Acerca de MAMBA',
          subtitle: 'Información de la aplicación',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
