import 'package:flutter/material.dart';

import '../../../../core/services/mamba_data_service.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = MambaDataService.fetchNotifications();
  }

  Future<void> _refresh() async {
    final next = MambaDataService.fetchNotifications();
    setState(() => _notifications = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text('Notificaciones',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        )),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _notifications,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('No cargaron. Toca para intentar de nuevo.'),
                      ),
                    );
                  }
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 170),
                          Icon(Icons.notifications_none_rounded,
                              size: 48, color: AppColors.primary),
                          SizedBox(height: 16),
                          Center(child: Text('Todavía no tienes notificaciones.')),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isUnread = item['read_at'] == null;
                        return Material(
                          color: isUnread
                              ? AppColors.primary.withValues(alpha: .10)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: .16),
                              child: Icon(_iconFor('${item['kind']}'), color: AppColors.primary),
                            ),
                            title: Text('${item['title'] ?? 'Novedad en MAMBA'}'),
                            subtitle: Text('${item['body'] ?? ''}'),
                            trailing: isUnread
                                ? const Icon(Icons.circle, size: 9, color: AppColors.primary)
                                : null,
                            onTap: isUnread
                                ? () async {
                                    await MambaDataService.markNotificationRead('${item['id']}');
                                    if (mounted) _refresh();
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'booking' => Icons.confirmation_number_outlined,
        'review' => Icons.star_outline_rounded,
        'follow' => Icons.person_add_alt_1_rounded,
        _ => Icons.notifications_none_rounded,
      };
}
