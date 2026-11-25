import 'package:flutter/material.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/account_session.dart';
import '../../../calendar/presentation/widgets/calendar_month.dart';
import 'manage_bookings_page.dart';

bool sameAgendaDay(Object? raw, DateTime day) {
  final date = DateTime.tryParse('$raw');
  return date != null &&
      date.year == day.year &&
      date.month == day.month &&
      date.day == day.day;
}

List<Map<String, dynamic>> hostAgendaForDate(
  List<Map<String, dynamic>> rows,
  String hostId,
  DateTime day, {
  String? planId,
}) => rows
    .where(
      (r) =>
          r['provider_id'] == hostId &&
          sameAgendaDay(r['date'], day) &&
          (planId == null || r['experience_id'] == planId),
    )
    .toList();

class HostAgendaPage extends StatefulWidget {
  const HostAgendaPage({super.key, this.hostId, this.loader, this.initialDate});
  final String? hostId;
  final DateTime? initialDate;
  final Future<List<Map<String, dynamic>>> Function()? loader;
  @override
  State<HostAgendaPage> createState() => _HostAgendaPageState();
}

class _HostAgendaPageState extends State<HostAgendaPage> {
  late DateTime _day = widget.initialDate ?? DateTime.now();
  String? _plan;
  String get _hostId =>
      widget.hostId ?? '${AccountSession.instance.account?.host?['id'] ?? ''}';
  late Future<List<Map<String, dynamic>>> _future = _load();
  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loader != null) return widget.loader!();
    if (!AccountSession.instance.isHost) {
      throw StateError('Sin permisos de anfitrión');
    }
    final start = DateTime(
      _day.year,
      _day.month,
      1,
    ).toIso8601String().substring(0, 10);
    final end = DateTime(
      _day.year,
      _day.month + 1,
      1,
    ).toIso8601String().substring(0, 10);
    return await AccountService.client
        .from('my_bookings')
        .select()
        .eq('provider_id', _hostId)
        .gte('date', start)
        .lt('date', end)
        .order('date');
  }

  void _refresh() => setState(() => _future = _load());
  void _selectDay(DateTime date) {
    setState(() {
      final changed = _day.month != date.month || _day.year != date.year;
      _day = date;
      if (changed) _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Agenda de mis planes'),
      actions: [
        IconButton(
          tooltip: 'Hoy',
          onPressed: () => _selectDay(DateTime.now()),
          icon: const Icon(Icons.today_outlined),
        ),
        IconButton(
          tooltip: 'Actualizar agenda',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text('Reintentar cargar mi agenda'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!
            .where((r) => r['provider_id'] == _hostId)
            .toList();
        final plans = {
          for (final r in rows)
            '${r['experience_id']}': '${r['experience_title']}',
        };
        final dayRows = hostAgendaForDate(rows, _hostId, _day, planId: _plan);
        final active = dayRows
            .where((r) => ['requested', 'accepted'].contains(r['status']))
            .toList();
        final guests = active.fold<int>(
          0,
          (sum, r) =>
              sum +
              (r['adults'] as num? ?? 0).toInt() +
              (r['minors'] as num? ?? 0).toInt(),
        );
        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
            children: [
              const Text(
                'Inscripciones y participantes de las experiencias que tú ofreces.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: plans.containsKey(_plan) ? _plan : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por plan',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos mis planes'),
                  ),
                  for (final e in plans.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _plan = v),
              ),
              const SizedBox(height: 20),
              CalendarMonth(
                selectedDate: _day,
                onDateSelected: _selectDay,
                onMonthChanged: (d) => _selectDay(DateTime(d.year, d.month, 1)),
                eventLoader: (date) => rows
                    .where(
                      (r) =>
                          (_plan == null || r['experience_id'] == _plan) &&
                          sameAgendaDay(r['date'], date) &&
                          ['requested', 'accepted'].contains(r['status']),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                '${_day.day}/${_day.month}/${_day.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${active.length} inscripciones activas · $guests participantes',
              ),
              const SizedBox(height: 12),
              if (dayRows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No hay inscripciones para tus planes en esta fecha. Los días con inscripciones activas aparecen marcados en el calendario.',
                  ),
                ),
              for (final row in dayRows)
                Card(
                  child: ListTile(
                    title: Text('${row['experience_title']}'),
                    subtitle: Text(
                      '${bookingStatusLabel('${row['status']}')}\n${row['adults'] ?? 0} adultos · ${row['minors'] ?? 0} menores',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageBookingsPage(
                            asHost: true,
                            experienceId: '${row['experience_id']}',
                            date: '${row['date']}',
                          ),
                        ),
                      );
                      if (mounted) _refresh();
                    },
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageBookingsPage(asHost: true),
                    ),
                  );
                  if (mounted) _refresh();
                },
                icon: const Icon(Icons.people_outline),
                label: const Text('Gestionar todas las inscripciones'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
