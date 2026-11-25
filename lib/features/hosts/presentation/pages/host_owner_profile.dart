import 'package:flutter/material.dart';
import '../../../../shared/widgets/mapo_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editable_profile_hero.dart';
import '../../../../shared/widgets/data_form_page.dart';
import '../../../profile/presentation/pages/profile_settings_page.dart';

class HostOwnerProfile extends StatefulWidget {
  const HostOwnerProfile({
    super.key,
    required this.account,
    required this.onChanged,
    this.pickPhoto,
  });
  final AccountSnapshot account;
  final VoidCallback onChanged;
  final Future<String?> Function()? pickPhoto;
  @override
  State<HostOwnerProfile> createState() => _HostOwnerProfileState();
}

class _HostOwnerProfileState extends State<HostOwnerProfile> {
  bool _busy = false;
  Future<void> _remove(Map<String, dynamic> photo) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Quitar este momento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (approved == true) {
      try {
        await AccountService.client
            .from('profile_photos')
            .delete()
            .eq('id', photo['id']);
        if (mounted) widget.onChanged();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AccountService.error(e))));
        }
      }
    }
  }

  Future<void> _photo(String field) async {
    setState(() => _busy = true);
    try {
      final url =
          await (widget.pickPhoto?.call() ?? MediaService.pickAndUpload());
      if (url == null) return;
      if (field == 'gallery') {
        await AccountService.client.from('profile_photos').insert({
          'user_id': AccountService.userId,
          'url': url,
        });
      } else {
        await AccountService.action('update_host_profile', {
          ...widget.account.host!,
          field: url,
        });
      }
      if (mounted) {
        widget.onChanged();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AccountService.error(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataFormPage(
          title: 'Editar perfil de anfitrión',
          initial: widget.account.host!,
          fields: const [
            DataField('display_name', 'Nombre público'),
            DataField('handle', 'Usuario, sin @'),
            DataField('city', 'Ciudad'),
            DataField('bio', 'Tu historia como anfitrión', lines: 5),
          ],
          onSave: (data) => AccountService.action('update_host_profile', {
            ...widget.account.host!,
            ...data,
          }),
        ),
      ),
    );
    if (mounted) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.account.host!, photos = widget.account.photos;
    final handle = '${host['handle'] ?? ''}'.trim().replaceFirst(
      RegExp(r'^@+'),
      '',
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => widget.onChanged(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: EditableProfileHero(
                title: handle.isEmpty ? 'Elige tu usuario' : '@$handle',
                avatar: host['avatar_url'],
                cover: host['cover_url'],
                busy: _busy,
                onAvatar: () => _photo('avatar_url'),
                onCover: () => _photo('cover_url'),
                onSettings: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage(),
                    ),
                  );
                  if (mounted) widget.onChanged();
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 130),
              sliver: SliverList.list(
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${host['display_name']}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _edit,
                        child: const Text('Editar perfil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${host['city']}')),
                      const Chip(label: Text('Anfitrión')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${host['bio'] ?? ''}',
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => context.push('/host/${host['id']}'),
                    icon: const Icon(Icons.visibility_outlined, size: 19),
                    label: const Text('Así ven mi perfil los viajeros'),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mis momentos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Añadir foto',
                        onPressed: _busy || photos.length >= 24
                            ? null
                            : () => _photo('gallery'),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ],
                  ),
                  if (photos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Comparte las personas, lugares y detalles que hacen especial tu forma de viajar.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (photos.isNotEmpty)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 12),
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        for (final photo in photos)
                          GestureDetector(
                            onLongPress: () => _remove(photo),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: MapoNetworkImage(
                                imageUrl: '${photo['url']}',
                                fit: BoxFit.cover,
                                memCacheWidth: 400,
                                errorWidget: (_, _, _) =>
                                    const Icon(Icons.image_outlined),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tus fotos de perfil se guardan con tu cuenta.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
