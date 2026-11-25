import 'package:flutter/material.dart';
import '../../../../core/services/account_service.dart';

class HostReviewPage extends StatefulWidget {
  const HostReviewPage({super.key});
  @override
  State<HostReviewPage> createState() => _HostReviewPageState();
}

class _HostReviewPageState extends State<HostReviewPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  bool _busy = false;
  Future<List<Map<String, dynamic>>> _load() async {
    final account = await AccountService.load();
    if (!account.isAdmin) throw StateError('Acceso restringido');
    return AccountService.client
        .from('host_applications')
        .select()
        .inFilter('status', [
          'submitted',
          'under_review',
          'approved',
          'suspended',
        ])
        .order('created_at');
  }

  Future<void> _review(Map<String, dynamic> a, String status) async {
    final notes = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(switch (status) {
          'approved' => 'Aprobar anfitrión',
          'rejected' => 'Solicitar ajustes',
          _ => 'Suspender anfitrión',
        }),
        content: TextField(
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observaciones para el anfitrión',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    final text = notes.text.trim();
    notes.dispose();
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await AccountService.action('review_application', {
        'user_id': a['user_id'],
        'status': status,
        'notes': text,
      });
      if (mounted) setState(() => _future = _load());
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Revisión de anfitriones')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Acceso restringido o conexión no disponible.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay solicitudes por revisar.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: snapshot.data!
              .map(
                (a) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${a['business_name']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('${a['city']}'),
                        Text('${a['experience_description']}'),
                        Text(switch (a['status']) {
                          'approved' => 'Aprobado',
                          'suspended' => 'Suspendido',
                          _ => 'Pendiente de revisión',
                        }),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (a['status'] != 'approved')
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _review(a, 'approved'),
                                child: const Text('Aprobar'),
                              ),
                            if ([
                              'submitted',
                              'under_review',
                            ].contains(a['status']))
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _review(a, 'rejected'),
                                child: const Text('Solicitar ajustes'),
                              ),
                            if (a['status'] == 'approved')
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _review(a, 'suspended'),
                                child: const Text('Suspender'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
