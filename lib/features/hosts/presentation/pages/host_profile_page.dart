import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/mamba_data_service.dart';
import '../../../reviews/domain/colombian_rating.dart';
import '../../../reviews/presentation/widgets/colombian_rating_badge.dart';

class HostProfilePage extends StatefulWidget {
  const HostProfilePage({super.key, required this.hostId});

  final String hostId;

  @override
  State<HostProfilePage> createState() => _HostProfilePageState();
}

class _HostProfilePageState extends State<HostProfilePage> {
  bool _following = false;
  int _selectedTab = 0;
  Map<String, dynamic>? _host;
  List<Map<String, dynamic>> _experiences = [];
  List<Map<String, String>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await Future.wait([
      MambaDataService.fetchHost(widget.hostId),
      MambaDataService.fetchExperiencesForHost(widget.hostId),
      MambaDataService.fetchReviewsForHost(widget.hostId),
      MambaDataService.isFollowingHost(widget.hostId),
    ]);
    if (!mounted) return;
    setState(() {
      _host = data[0] as Map<String, dynamic>?;
      _experiences = data[1] as List<Map<String, dynamic>>;
      _reviews = data[2] as List<Map<String, String>>;
      _following = data[3] as bool;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final host = _host;
    if (host == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver',
            onPressed: () => _close(context),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ),
        body: const Center(child: Text('No encontramos este perfil.')),
      );
    }

    final experiences = _experiences;
    final reviews = _reviews;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 238,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: host['cover'] ?? host['avatar']!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: AppColors.surfaceRaised,
                              child: Icon(Icons.landscape_rounded, size: 52),
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x33000000), Color(0xAA101412)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: IconButton(
                            tooltip: 'Volver',
                            onPressed: () => _close(context),
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white, size: 32),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 8,
                          child: _GlassIconButton(
                            icon: Icons.ios_share_rounded,
                            label: 'Compartir perfil',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Compartir estará disponible pronto.'),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: -42,
                          child: _HostAvatar(url: host['avatar']!, size: 100),
                        ),
                        Positioned(
                          right: 18,
                          bottom: 18,
                          child: _VerifiedBadge(
                            verified: host['verified'] == 'true',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(132, 8, 18, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            host['name']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            host['handle']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.primary, size: 17),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(host['location']!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(host['bio']!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              )),
                          const SizedBox(height: 14),
                          _HostRatingSummary(
                            label: host['host_rating']!,
                            reviewCount: host['reviews']!,
                            joined: host['joined'] ?? 'Anfitrión local',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: FilledButton.icon(
                                  onPressed: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Los mensajes estarán disponibles pronto.'),
                                  )),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  label: const Text('Contactar'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final following = await MambaDataService
                                          .toggleHostFollow(widget.hostId, _following);
                                      if (!mounted) return;
                                      setState(() => _following = following);
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No pudimos actualizar el seguimiento.')),
                                      );
                                    }
                                  },
                                  icon: Icon(_following
                                      ? Icons.check_rounded
                                      : Icons.person_add_alt_1_rounded),
                                  label: Text(_following ? 'Siguiendo' : 'Seguir'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: AppColors.border.withValues(alpha: .9)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ProfileTabButton(
                                    label: 'Experiencias',
                                    selected: _selectedTab == 0,
                                    onTap: () => setState(() => _selectedTab = 0),
                                  ),
                                ),
                                Expanded(
                                  child: _ProfileTabButton(
                                    label: 'Reseñas',
                                    selected: _selectedTab == 1,
                                    onTap: () => setState(() => _selectedTab = 1),
                                  ),
                                ),
                                Expanded(
                                  child: _ProfileTabButton(
                                    label: 'Sobre mí',
                                    selected: _selectedTab == 2,
                                    onTap: () => setState(() => _selectedTab = 2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ],
                ),
              ),
            ),
            if (_selectedTab == 0) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Experiencias para vivir',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 3),
                      Text('Planes de ${host['name']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
              ),
              if (experiences.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                      child: Text('Este anfitrión aún no tiene planes publicados.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  sliver: SliverList.separated(
                    itemCount: experiences.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _ExperienceCard(experience: experiences[index]),
                  ),
                ),
            ] else if (_selectedTab == 1 && reviews.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Este anfitrión aún no tiene reseñas.')),
              )
            else if (_selectedTab == 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                sliver: SliverList.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _HostReviewCard(review: reviews[index]),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sobre ${host['name']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 12),
                        Text(host['bio']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            )),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(host['location']!)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: const Color(0x55303030),
              child: IconButton(
                tooltip: label,
                onPressed: onTap,
                icon: Icon(icon, color: Colors.white),
              ),
            ),
          ),
        ),
      );
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xB8101412),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(verified ? Icons.verified_rounded : Icons.explore_rounded,
                  color: verified ? AppColors.primary : Colors.white, size: 17),
              const SizedBox(width: 7),
              Text(verified ? 'ANFITRIÓN VERIFICADO' : 'ANFITRIÓN LOCAL',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

class _HostRatingSummary extends StatelessWidget {
  const _HostRatingSummary({required this.label, required this.reviewCount, required this.joined});
  final String label;
  final String reviewCount;
  final String joined;

  @override
  Widget build(BuildContext context) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          ColombianRatingBadge(
            prominent: true,
            target: ColombianRatingTarget.host,
            label: label,
          ),
          Text('$reviewCount reseñas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  )),
          Container(width: 1, height: 16, color: AppColors.border),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_month_outlined,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(joined,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    )),
          ]),
        ],
      );
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _HostReviewCard extends StatelessWidget {
  const _HostReviewCard({required this.review});
  final Map<String, String> review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: .16),
            child: Text(review['author']!.substring(0, 1),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(review['author']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text(review['date']!, style: theme.textTheme.bodySmall),
            ]),
          ),
          ColombianRatingBadge(label: review['rating']!, target: ColombianRatingTarget.host),
        ]),
        const SizedBox(height: 12),
        Text(review['comment']!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.local_activity_outlined, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(review['experience']!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ),
        ]),
      ]),
    );
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({required this.url, required this.size});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const ColoredBox(
              color: AppColors.surfaceRaised,
              child: Icon(Icons.storefront_rounded),
            ),
          ),
        ),
      );
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});
  final Map<String, dynamic> experience;

  @override
  Widget build(BuildContext context) {
    final images = experience['images'] as List<String>;
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.emeraldGlow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/experience/${experience['id']}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
              SizedBox(
              width: 132,
              height: 184,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: images.first,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const ColoredBox(
                          color: AppColors.surfaceRaised,
                          child: Icon(Icons.landscape_outlined)),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 9,
                      left: 8,
                      right: 4,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ColombianRatingBadge(
                          label: experience['experience_rating'] as String? ??
                              ColombianRating.unaChimba.label,
                          target: ColombianRatingTarget.experience,
                          overImage: true,
                        ),
                      ),
                    ),
                  ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(experience['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(experience['location'] as String? ?? 'Ubicación por confirmar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(experience['duration'] as String? ?? 'Horario por confirmar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Desde ${experience['price']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: FilledButton(
                      onPressed: () => context.push('/experience/${experience['id']}'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ver plan'),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
