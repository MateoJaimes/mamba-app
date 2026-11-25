import '../../../../shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/account_service.dart';
import 'review_booking_page.dart';

String bookingStatusLabel(String status) => switch (status) {
  'accepted' => 'Confirmada',
  'rejected' => 'Rechazada',
  'cancelled' => 'Cancelada',
  'completed' => 'Completada',
  _ => 'Pendiente de confirmación',
};

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({
    super.key,
    this.asHost = false,
    this.experienceId,
    this.date,
  });
  final bool asHost;
  final String? experienceId, date;
  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  String? _busy;
  Future<List<Map<String, dynamic>>> _load() async {
    var query = AccountService.client.from('my_bookings').select();
    if (widget.asHost) {
      final a = await AccountService.load();
      if (!a.canHost) throw StateError('Sin permisos de anfitrión');
      query = query.eq('provider_id', a.host!['id']);
    } else {
      query = query.eq('user_id', AccountService.userId);
    }
    if (widget.experienceId != null) {
      query = query.eq('experience_id', widget.experienceId!);
    }
    if (widget.date != null) query = query.eq('date', widget.date!);
    return await query.order('date', ascending: false);
  }

  Future<void> _change(Map<String, dynamic> b, String status) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar inscripción'),
        content: Text(
          '¿Cambiar la inscripción a “${bookingStatusLabel(status)}”?',
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
    if (approved != true || !mounted) return;
    setState(() => _busy = b['id'] as String);
    try {
      await AccountService.action('booking_status', {
        'id': b['id'],
        'status': status,
      });
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AccountService.error(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.asHost ? 'Inscripciones y participantes' : 'Mis inscripciones',
      ),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => _future = _load()),
              child: const Text('No pudimos cargar. Reintentar'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('Todavía no hay inscripciones.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: snapshot.data!.map((b) {
              final status = b['status'];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b['experience_title']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${b['date']} · ${b['adults']} adultos · ${b['minors']} menores',
                      ),
                      Text(bookingStatusLabel('$status')),
                      MoneyText(
                        amount: (b['total_amount'] as num),
                        prefix: 'Total estimado: ',
                        suffix: ' · Pago presencial al anfitrión',
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (status == 'accepted' && widget.asHost)
                            TextButton(
                              onPressed: _busy != null
                                  ? null
                                  : () => _change(b, 'completed'),
                              child: const Text('Marcar completada'),
                            ),
                          if (status == 'completed' && !widget.asHost)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewBookingPage(booking: b),
                                ),
                              ),
                              child: const Text('Dejar mi reseña'),
                            ),
                          if ((!widget.asHost && status == 'requested') ||
                              status == 'accepted')
                            TextButton(
                              onPressed: _busy != null
                                  ? null
                                  : () => _change(b, 'cancelled'),
                              child: const Text('Cancelar inscripción'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    ),
  );
}
