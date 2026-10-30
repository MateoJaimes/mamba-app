import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/scroll_edge_blur.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../bookings/data/local_booking_store.dart';
import '../../../hosts/data/demo_host_catalog.dart';
import '../../../reviews/domain/colombian_rating.dart';
import '../../../reviews/presentation/widgets/colombian_rating_badge.dart';

class ExperienceDetailPage extends StatefulWidget {
  const ExperienceDetailPage({super.key, required this.experienceId});

  final String experienceId;

  @override
  State<ExperienceDetailPage> createState() => _ExperienceDetailPageState();
}

class _ExperienceDetailPageState extends State<ExperienceDetailPage> {
  int _imageIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experience = DemoHostCatalog.experienceById(widget.experienceId);
    if (experience == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Cerrar',
            onPressed: () => _close(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: const Center(child: Text('No encontramos este plan.')),
      );
    }

    final images = experience['images'] as List<String>;
    final providerId = experience['provider_id'] as String;
    final host = DemoHostCatalog.hostById(providerId);
    final theme = Theme.of(context);
    return Scaffold(
      body: ScrollEdgeBlur(
        controller: _scrollController,
        bottomExtent: 56,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: IconButton(
                tooltip: 'Cerrar detalle',
                onPressed: () => _close(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) =>
                          setState(() => _imageIndex = index),
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: AppColors.surfaceRaised,
                          child: Icon(Icons.landscape_outlined, size: 52),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x55000000),
                            Colors.transparent,
                            Color(0x99000000),
                          ],
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 18,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: index == _imageIndex ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: index == _imageIndex ? 1 : .58,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 18,
                      bottom: images.length > 1 ? 42 : 18,
                      child: ColombianRatingBadge(
                        label:
                            experience['experience_rating'] as String? ??
                            ColombianRating.unaChimba.label,
                        target: ColombianRatingTarget.experience,
                        prominent: true,
                        overImage: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
              sliver: SliverList.list(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: experience['location'] as String,
                      ),
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: experience['duration'] as String? ?? '3 horas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    experience['title'] as String,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 22),
                  if (host != null)
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => context.push('/host/$providerId'),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Row(
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: host['avatar']!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Una experiencia de',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      host['name']!,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    Text(
                                      host['handle']!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Sobre este plan'),
                  const SizedBox(height: 8),
                  Text(
                    experience['description'] as String,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Lo que vivirás'),
                  const SizedBox(height: 10),
                  _DetailLine(
                    icon: Icons.groups_2_outlined,
                    text:
                        'Grupo pequeño · hasta ${experience['max_people'] ?? 10} personas',
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Punto de encuentro'),
                  const SizedBox(height: 8),
                  Text(
                    experience['meeting_point'] as String? ??
                        experience['location'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MeetingPointMap(experience: experience),
                  const SizedBox(height: 6),
                  Text(
                    'El marcador muestra la ubicación de referencia del plan.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _DetailLine(
                    icon: Icons.check_circle_outline_rounded,
                    text:
                        experience['includes'] as String? ??
                        'Acompañamiento de anfitrión local',
                  ),
                  _DetailLine(
                    icon: Icons.info_outline_rounded,
                    text:
                        experience['requirements'] as String? ??
                        'Llega 10 minutos antes y trae ropa cómoda.',
                  ),
                  const SizedBox(height: 14),
                  _AgePolicyCard(experience: experience),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El pago aún no está habilitado. Tu inscripción local no realiza ningún cobro.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .98),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 20,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por persona', style: theme.textTheme.bodySmall),
                    Text(
                      experience['price'] as String,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showJoinFlow(context, experience),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('Me apunto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showJoinFlow(
    BuildContext context,
    Map<String, dynamic> experience,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _JoinExperienceSheet(experience: experience),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Inscripción guardada en este dispositivo. Aún no es una reserva confirmada.',
        ),
      ),
    );
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/feed');
    }
  }
}

class _JoinExperienceSheet extends StatefulWidget {
  const _JoinExperienceSheet({required this.experience});
  final Map<String, dynamic> experience;

  @override
  State<_JoinExperienceSheet> createState() => _JoinExperienceSheetState();
}

class _JoinExperienceSheetState extends State<_JoinExperienceSheet> {
  late final List<DateTime> _dates;
  int _selectedDate = 0;
  int _adults = 1;
  int _minors = 0;
  bool _guardianConfirmed = false;
  bool _minimumAgeConfirmed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final first = DateTime.now().add(const Duration(days: 1));
    _dates = List.generate(
      4,
      (index) => DateTime(first.year, first.month, first.day + index * 7),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await LocalBookingStore.create(
        experience: widget.experience,
        date: _dates[_selectedDate],
        adults: _adults,
        minors: _minors,
        minorsSupervisionConfirmed: _minors == 0 || _guardianConfirmed,
        minimumAgeConfirmed:
            _minimumAgeConfirmed ||
            widget.experience['age_policy'] != 'minimum_age',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos guardar la inscripción local.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxGuests = (widget.experience['max_people'] as int? ?? 10).clamp(
      1,
      10,
    );
    final agePolicy = widget.experience['age_policy'] as String? ?? 'all_ages';
    final minAge = widget.experience['minimum_age'] as int? ?? 0;
    final requiresGuardian =
        widget.experience['minor_supervision_required'] as bool? ?? false;
    final canSubmit =
        !_saving &&
        _adults + _minors <= maxGuests &&
        (agePolicy != 'minimum_age' || _minimumAgeConfirmed) &&
        (_minors == 0 || !requiresGuardian || _guardianConfirmed);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '¿Te apuntas al plan?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Elige una fecha y cuántas personas van.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Text(
              'Fecha disponible',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final selected = index == _selectedDate;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDate = index),
                    label: Text(
                      '${_weekday(date.weekday)} ${date.day} ${_month(date.month)}',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _AttendeeCounter(
              label: 'Personas adultas',
              count: _adults,
              onDecrease: _adults <= 1 ? null : () => setState(() => _adults--),
              onIncrease: _adults + _minors >= maxGuests
                  ? null
                  : () => setState(() => _adults++),
            ),
            if (agePolicy != 'adults_only')
              _AttendeeCounter(
                label: 'Menores de 18 años',
                count: _minors,
                onDecrease: _minors == 0
                    ? null
                    : () => setState(() {
                        _minors--;
                        _guardianConfirmed = false;
                      }),
                onIncrease: _adults + _minors >= maxGuests
                    ? null
                    : () => setState(() => _minors++),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cupo máximo: $maxGuests personas',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (agePolicy == 'minimum_age')
              CheckboxListTile(
                value: _minimumAgeConfirmed,
                onChanged: (value) =>
                    setState(() => _minimumAgeConfirmed = value ?? false),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Confirmo que todos cumplen la edad mínima de $minAge años.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (_minors > 0 && requiresGuardian)
              CheckboxListTile(
                value: _guardianConfirmed,
                onChanged: (value) =>
                    setState(() => _guardianConfirmed = value ?? false),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Confirmo que cada menor asistirá con una persona adulta responsable.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Total estimado: ${_totalPrice(widget.experience['price'] as String, _adults + _minors)} · No se realiza ningún pago.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar mi inscripción'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Solicitud local de prueba, pendiente de confirmación del anfitrión.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _weekday(int day) =>
    const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][day - 1];
String _month(int month) => const [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
][month - 1];

String _totalPrice(String price, int guests) {
  final amount = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  final total = amount * guests;
  final digits = total.toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, digits.length);
    groups.insert(0, digits.substring(start, end));
  }
  return '\$${groups.join('.')}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17, color: AppColors.primary),
    label: Text(label),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 11),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _AgePolicyCard extends StatelessWidget {
  const _AgePolicyCard({required this.experience});

  final Map<String, dynamic> experience;

  @override
  Widget build(BuildContext context) {
    final policy = experience['age_policy'] as String? ?? 'all_ages';
    final minimumAge = experience['minimum_age'] as int? ?? 0;
    final title = switch (policy) {
      'adults_only' => 'Solo mayores de edad',
      'minimum_age' => 'Desde $minimumAge años',
      _ => 'Plan apto para todas las edades',
    };
    final note =
        experience['age_policy_note'] as String? ??
        'Consulta las condiciones de edad antes de apuntarte.';
    final icon = policy == 'adults_only'
        ? Icons.no_accounts_outlined
        : Icons.family_restroom_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(note, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingPointMap extends StatelessWidget {
  const _MeetingPointMap({required this.experience});

  final Map<String, dynamic> experience;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(
      (experience['latitude'] as num?)?.toDouble() ?? 6.2442,
      (experience['longitude'] as num?)?.toDouble() ?? -75.5812,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            minZoom: 4,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mamba.mamba_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 54,
                  height: 62,
                  child: const Icon(
                    Icons.location_pin,
                    size: 52,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: const [
                TextSourceAttribution(
                  '© Stadia Maps · © OpenMapTiles · © OpenStreetMap',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendeeCounter extends StatelessWidget {
  const _AttendeeCounter({
    required this.label,
    required this.count,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int count;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      IconButton(
        tooltip: 'Quitar una persona',
        onPressed: onDecrease,
        icon: const Icon(Icons.remove_circle_outline_rounded),
      ),
      Text('$count', style: Theme.of(context).textTheme.titleMedium),
      IconButton(
        tooltip: 'Agregar una persona',
        onPressed: onIncrease,
        icon: const Icon(Icons.add_circle_outline_rounded),
      ),
    ],
  );
}
