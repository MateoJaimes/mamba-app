import '../../../../shared/widgets/mapo_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/account_session.dart';
import '../../../../core/services/host_plan_service.dart';
import '../../../../shared/widgets/money_text.dart';
import 'experience_editor_page.dart';

class HostPlansPage extends StatefulWidget {
  const HostPlansPage({super.key});
  @override
  State<HostPlansPage> createState() => _HostPlansPageState();
}

class _HostPlansPageState extends State<HostPlansPage> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    final account = AccountSession.instance.account;
    if (account?.canHost != true) {
      return const Scaffold(
        body: Center(
          child: Text('Tu cuenta necesita aprobación para gestionar planes.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis planes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar planes',
            onPressed: () => setState(() => _revision++),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
        children: [
          const Text(
            'Crea experiencias, actualiza sus detalles y decide cuáles están disponibles.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExperienceEditorPage()),
              );
              if (mounted) setState(() => _revision++);
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear plan'),
          ),
          const SizedBox(height: 20),
          HostPlanList(
            key: ValueKey(_revision),
            hostId: account!.host!['id'] as String,
          ),
        ],
      ),
    );
  }
}

class HostPlanList extends StatefulWidget {
  const HostPlanList({super.key, required this.hostId, this.loader});
  final String hostId;
  final Future<List<Map<String, dynamic>>> Function()? loader;
  @override
  State<HostPlanList> createState() => _HostPlanListState();
}

class _HostPlanListState extends State<HostPlanList> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  String _status = 'all';
  String? _busy;
  Future<List<Map<String, dynamic>>> _load() =>
      widget.loader?.call() ?? HostPlanService.load(widget.hostId);
  void _refresh() => setState(() => _future = _load());
  Future<void> _edit(Map<String, dynamic> plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExperienceEditorPage(experience: plan)),
    );
    if (mounted) _refresh();
  }

  Future<void> _change(Map<String, dynamic> plan, String status) async {
    if (status == 'archived') {
      final approved = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Archivar este plan?'),
          content: const Text(
            'Dejará de aparecer en el catálogo. Sus inscripciones e historial se conservarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Archivar'),
            ),
          ],
        ),
      );
      if (approved != true) return;
    }
    setState(() => _busy = '${plan['id']}');
    try {
      await HostPlanService.changeStatus(plan, status);
      if (mounted) _refresh();
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

  Widget _planCard(Map<String, dynamic> plan) {
    final images = List<Map<String, dynamic>>.from(
      plan['experience_images'] as List? ?? [],
    )..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    final cover = images.isEmpty ? null : images.first['image_url'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: ColoredBox(
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover != null)
                      MapoNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        memCacheWidth: 900,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.landscape_outlined, size: 48),
                      )
                    else
                      const ColoredBox(
                        color: AppColors.surfaceRaised,
                        child: Icon(
                          Icons.landscape_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xED0E1B34),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          experienceStatusLabel('${plan['status']}'),
                          style: TextStyle(
                            color: plan['status'] == 'published'
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: PopupMenuButton<String>(
                        tooltip: 'Opciones de ${plan['title']}',
                        enabled: _busy == null,
                        onSelected: (value) {
                          if (value == 'view') {
                            context.push('/experience/${plan['id']}');
                          } else {
                            _change(plan, value);
                          }
                        },
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        color: AppColors.surfaceRaised,
                        itemBuilder: (_) => [
                          if (plan['status'] == 'published')
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('Ver publicación'),
                            ),
                          if (plan['status'] == 'published')
                            const PopupMenuItem(
                              value: 'paused',
                              child: Text('Pausar'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'published',
                              child: Text('Publicar'),
                            ),
                          if (plan['status'] != 'archived')
                            const PopupMenuItem(
                              value: 'archived',
                              child: Text('Archivar'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan['title']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (plan['location_label'] != null)
                      Text(
                        '${plan['location_label']}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MoneyText(
                                amount: plan['price_amount'] as num,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'por persona',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _busy == null ? () => _edit(plan) : null,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar plan'),
                        ),
                      ],
                    ),
                    if (_busy == '${plan['id']}')
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: _refresh,
          child: const Text('Reintentar cargar mis planes'),
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final all = snapshot.data!,
          plans = all
              .where((p) => _status == 'all' || p['status'] == _status)
              .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in [
                  'all',
                  'published',
                  'draft',
                  'paused',
                  'archived',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        status == 'all'
                            ? 'Todos (${all.length})'
                            : experienceStatusLabel(status),
                      ),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No hay planes en este estado. Crea uno o cambia el filtro.',
              ),
            ),
          for (final plan in plans) _planCard(plan),
        ],
      );
    },
  );
}
