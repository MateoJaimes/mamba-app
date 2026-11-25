import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/env.dart';
import '../../../../core/services/account_service.dart';
import '../../../../shared/widgets/data_form_page.dart';
import '../../../../shared/widgets/mapo_logo.dart';
import '../../../hosts/presentation/pages/host_dashboard_page.dart';
import '../../../hosts/presentation/pages/host_review_page.dart';
import '../../../hosts/presentation/pages/manage_bookings_page.dart';
import 'profile_collection_page.dart';
import 'profile_preferences_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key, this.loader});
  final Future<AccountSnapshot> Function()? loader;
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  Future<AccountSnapshot>? _future;
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
    if (mounted && AppEnvironment.hasSupabaseConfig) _refresh();
  }

  Future<void> _edit(AccountSnapshot a) => _open(
    DataFormPage(
      title: 'Editar mi perfil',
      initial: a.profile,
      fields: const [
        DataField('display_name', 'Nombre público'),

        DataField('bio', 'Sobre mí', lines: 4, required: false),
      ],
      onSave: (data) async {
        await AccountService.client
            .from('profiles')
            .update(data)
            .eq('id', AccountService.userId);
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configuración')),
    body: SafeArea(
      child: FutureBuilder<AccountSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (_future == null) {
            return const Center(
              child: Text('Inicia sesión para administrar tu perfil.'),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _refresh,
                child: const Text('No pudimos cargar tu perfil. Reintentar'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final a = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
              children: [
                _item(
                  Icons.person_outline,
                  'Información personal',
                  () => _edit(a),
                ),
                _item(
                  Icons.location_on_outlined,
                  'País y ciudad',
                  () => _open(ProfilePreferencesPage(profile: a.profile)),
                ),
                _item(
                  Icons.currency_exchange,
                  'Divisa',
                  () => _open(
                    ProfilePreferencesPage(profile: a.profile, currency: true),
                  ),
                ),
                if (!a.canHost)
                  _item(
                    Icons.travel_explore,
                    a.canHost
                        ? 'Mi espacio de anfitrión'
                        : 'Quiero ser anfitrión',
                    () => _open(const HostDashboardPage()),
                  ),
                if (a.isAdmin)
                  _item(
                    Icons.admin_panel_settings_outlined,
                    'Revisión de anfitriones',
                    () => _open(const HostReviewPage()),
                  ),
                _item(
                  Icons.event_available_outlined,
                  'Mis inscripciones',
                  () => _open(const ManageBookingsPage()),
                ),
                _item(
                  Icons.bookmark_outline,
                  'Mis guardados',
                  () => _open(const ProfileCollectionPage()),
                ),
                _item(
                  Icons.rate_review_outlined,
                  'Mis reseñas',
                  () => _open(const ProfileCollectionPage(reviews: true)),
                ),
                _item(
                  Icons.notifications_outlined,
                  'Notificaciones',
                  () => context.push('/notifications'),
                ),
                _item(Icons.help_outline, 'Ayuda y soporte', () async {
                  final ok = await launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: 'somosmapoapp@gmail.com',
                      queryParameters: {'subject': 'Ayuda con MAPO'},
                    ),
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Escríbenos a somosmapoapp@gmail.com'),
                      ),
                    );
                  }
                }),
                _item(
                  Icons.info_outline,
                  'Acerca de MAPO',
                  () => showAboutDialog(
                    context: context,
                    applicationName: 'MAPO',
                    applicationIcon: const MapoLogo(
                      symbolOnly: true,
                      width: 52,
                    ),
                    applicationVersion: '1.0.0 · Alfa de prueba',
                    children: [
                      const Text(
                        'Descubre experiencias y conecta con anfitriones locales. Las inscripciones se confirman automáticamente según los cupos. El pago se realiza presencialmente con el anfitrión; la app no cobra. Soporte: somosmapoapp@gmail.com',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await AccountService.client.auth.signOut();
                      if (context.mounted) context.go('/auth');
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No pudimos cerrar la sesión. Reintenta.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  Widget _item(IconData icon, String title, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
