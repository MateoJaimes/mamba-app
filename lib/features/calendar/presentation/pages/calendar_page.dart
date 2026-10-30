import 'package:flutter/material.dart';

import '../../../bookings/data/local_booking_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/calendar_header.dart';
import '../widgets/calendar_month.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLocalBookings();
  }

  Future<void> _loadLocalBookings() async {
    try {
      await LocalBookingStore.getAll();
    } catch (_) {
      // Keep the calendar usable if local storage is temporarily unavailable.
    }
  }

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
                  const CalendarHeader(),
                  const SizedBox(height: 24),

                  CalendarMonth(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  _SelectedDateTitle(date: _selectedDate),

                  const SizedBox(height: 12),

                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: LocalBookingStore.changes,
                    builder: (context, bookings, _) => _BookingsForDate(
                      date: _selectedDate,
                      bookings: bookings,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDateTitle extends StatelessWidget {
  const _SelectedDateTitle({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      _formatDate(date),
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]}';
  }
}

class _BookingsForDate extends StatelessWidget {
  const _BookingsForDate({required this.date, required this.bookings});

  final DateTime date;
  final List<Map<String, dynamic>> bookings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateBookings = bookings.where((booking) {
      final bookingDate = DateTime.tryParse(booking['date'] as String? ?? '');
      return bookingDate != null &&
          bookingDate.year == date.year &&
          bookingDate.month == date.month &&
          bookingDate.day == date.day;
    }).toList();

    if (dateBookings.isNotEmpty) {
      return Column(
        children: dateBookings
            .map(
              (booking) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        booking['image'] as String? ?? '',
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 68,
                          height: 68,
                          child: Icon(Icons.landscape_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['experience_title'] as String? ??
                                'Experiencia',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            booking['provider_name'] as String? ?? 'Anfitrión',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '${booking['adults'] ?? booking['guests']} adultos · '
                            '${booking['minors'] ?? 0} menores · '
                            '${booking['status'] == 'requested' ? 'Pendiente de confirmación' : 'Inscripción local'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes experiencias este día',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando te apuntes a un plan, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
