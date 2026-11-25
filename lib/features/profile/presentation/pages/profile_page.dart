import '../../../../shared/widgets/editable_profile_hero.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/mapo_network_image.dart';
import '../../../../core/constants/env.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/services/plan_categories.dart';
import '../../../../shared/widgets/data_form_page.dart';
import 'profile_settings_page.dart';
import 'profile_preferences_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.loader, this.pickPhoto});
  final Future<String?> Function()? pickPhoto;
  final Future<AccountSnapshot> Function()? loader;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<AccountSnapshot>? _future;
  bool _uploading = false;
  @override
  void initState() {
    super.initState();
    if (widget.loader != null) {
      _future = widget.loader!();
    } else if (AppEnvironment.hasSupabaseConfig) {
      _future = AccountService.load();
    }
  }

  void _refresh() =>
      setState(() => _future = widget.loader?.call() ?? AccountService.load());
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _refresh();
  }

  void _error(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AccountService.error(e))));
    }
  }

  Future<void> _photo(String field) async {
    setState(() => _uploading = true);
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
        await AccountService.client
            .from('profiles')
            .update({field: url})
            .eq('id', AccountService.userId);
      }
      if (mounted) _refresh();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _edit(AccountSnapshot a) => _open(
    DataFormPage(
      title: 'Mi información',
      initial: a.profile,
      fields: const [
        DataField('display_name', 'Nombre público'),
        DataField('handle', 'Usuario', required: false),
        DataField('bio', 'Sobre mí', lines: 4, required: false),
        DataField(
          'interests',
          'Lo que me mueve',
          choices: PlanCategories.labels,
          multiple: true,
          required: false,
          maxSelections: 8,
        ),
      ],
      onSave: (data) async {
        await AccountService.client
            .from('profiles')
            .update(data)
            .eq('id', AccountService.userId);
      },
    ),
  );
  Widget _image(String? url) => url == null || url.isEmpty
      ? const ColoredBox(
          color: Color(0xFF1F3C54),
          child: Center(child: Icon(Icons.landscape_outlined, size: 48)),
        )
      : MapoNetworkImage(
          imageUrl: url,
          width: double.infinity,
          fit: BoxFit.cover,
          memCacheWidth: 1000,
          errorWidget: (_, _, _) =>
              const Center(child: Icon(Icons.image_outlined)),
        );
  Future<void> _remove(Map<String, dynamic> photo) async {
    final remove = await showDialog<bool>(
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
    if (remove == true) {
      try {
        await AccountService.client
            .from('profile_photos')
            .delete()
            .eq('id', photo['id']);
        if (mounted) _refresh();
      } catch (e) {
        _error(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder<AccountSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (_future == null) {
          return const Center(child: Text('Inicia sesión para ver tu perfil.'));
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text('Reintentar cargar mi perfil'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final a = snapshot.data!, p = a.profile;
        final avatar = p['avatar_url'] as String?;
        final handle = '${p['handle'] ?? ''}'.trim().replaceFirst(
          RegExp(r'^@+'),
          '',
        );
        final interests = List<String>.from(p['interests'] as List? ?? []);
        final location = [
          p['city'],
          p['country'],
        ].where((v) => v != null && '$v'.isNotEmpty).join(' · ');
        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await _future;
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: EditableProfileHero(
                  title: handle.isEmpty ? 'Elige tu usuario' : '@$handle',
                  avatar: avatar,
                  cover: p['cover_url'],
                  busy: _uploading,
                  onAvatar: () => _photo('avatar_url'),
                  onCover: () => _photo('cover_url'),
                  onSettings: () => _open(const ProfileSettingsPage()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 130),
                sliver: SliverList.list(
                  children: [
                    if (_uploading) const LinearProgressIndicator(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['display_name'] ?? 'Mi perfil'}',
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _edit(a),
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _open(ProfilePreferencesPage(profile: p)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location.isEmpty
                                  ? 'Añade tu ubicación'
                                  : location,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${p['bio'] ?? ''}'.isEmpty
                          ? 'Cuenta qué te gusta descubrir. Tu próxima aventura empieza aquí.'
                          : '${p['bio']}',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Lo que me mueve',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests.isEmpty
                          ? [
                              ActionChip(
                                label: const Text('Añadir intereses'),
                                avatar: const Icon(Icons.add, size: 17),
                                onPressed: () => _edit(a),
                              ),
                            ]
                          : interests
                                .map(
                                  (v) => Chip(
                                    label: Text(PlanCategories.labels[v] ?? v),
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mis momentos',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Añadir foto',
                          onPressed: _uploading || a.photos.length >= 24
                              ? null
                              : () => _photo('gallery'),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                      ],
                    ),
                    const Text(
                      'Tus fotos de perfil se guardan como imágenes públicas. Hasta 24 momentos. Mantén una foto pulsada para quitarla.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount:
                          a.photos.length + (a.photos.length < 24 ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == a.photos.length) {
                          return OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _uploading
                                ? null
                                : () => _photo('gallery'),
                            child: const Icon(Icons.add, size: 30),
                          );
                        }
                        final photo = a.photos[i];
                        return GestureDetector(
                          onLongPress: () => _remove(photo),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _image(photo['url']),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
