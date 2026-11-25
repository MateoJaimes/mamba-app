import 'host_owner_profile.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/account_session.dart';
import '../../../../shared/widgets/data_form_page.dart';

class HostDashboardPage extends StatefulWidget {
  const HostDashboardPage({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<HostDashboardPage> createState() => _HostDashboardPageState();
}

class _HostDashboardPageState extends State<HostDashboardPage> {
  late Future<AccountSnapshot> _future = AccountService.load();
  void _refresh() {
    setState(() => _future = AccountService.load());
    AccountSession.instance.refresh();
  }

  Future<void> _application(AccountSnapshot a) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataFormPage(
          title: 'Sé anfitrión de experiencias',
          description:
              'Cuéntanos qué plan quieres ofrecer. El equipo de MAPO revisará tu solicitud antes de habilitar publicaciones.',
          saveLabel: 'Enviar solicitud',
          initial: a.application ?? {},
          fields: const [
            DataField('business_name', 'Nombre público o emprendimiento'),
            DataField('city', 'Ciudad'),
            DataField(
              'experience_description',
              'Qué experiencias ofreces (mínimo 30 caracteres)',
              lines: 5,
            ),
          ],
          onSave: (data) => AccountService.action('submit_application', data),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded ? null : AppBar(title: const Text('Ser anfitrión')),
    body: FutureBuilder<AccountSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed: _refresh,
              child: const Text('No pudimos cargar. Reintentar'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final a = snapshot.data!;
        final status = a.application?['status'] as String? ?? 'not_applied';
        if (!a.canHost) {
          final label = switch (status) {
            'submitted' || 'under_review' => 'Estamos revisando tu solicitud',
            'rejected' => 'Tu solicitud necesita ajustes',
            'suspended' => 'Tu acceso está suspendido',
            _ => 'Comparte lo mejor de tu ciudad',
          };
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.travel_explore, size: 72),
              const SizedBox(height: 24),
              Text(label, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                status == 'submitted' || status == 'under_review'
                    ? 'Puedes seguir explorando como turista. Al aprobar tu solicitud, aquí podrás publicar planes y gestionar participantes.'
                    : 'Crea tu perfil de anfitrión, presenta tus experiencias y recibe solicitudes de personas que quieren conocerlas.',
              ),
              if (a.application?['reviewer_notes'] != null) ...[
                const SizedBox(height: 16),
                Text('Observaciones: ${a.application!['reviewer_notes']}'),
              ],
              const SizedBox(height: 24),
              if (['not_applied', 'draft', 'rejected'].contains(status))
                FilledButton(
                  onPressed: () => _application(a),
                  child: Text(
                    status == 'rejected'
                        ? 'Corregir y reenviar'
                        : 'Completar solicitud',
                  ),
                ),
              if (status == 'suspended')
                const Text(
                  'Escríbenos a somosmapoapp@gmail.com para revisar tu caso.',
                ),
            ],
          );
        }
        return HostOwnerProfile(account: a, onChanged: _refresh);
      },
    ),
  );
}
