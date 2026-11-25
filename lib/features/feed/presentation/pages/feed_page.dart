import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../../../../shared/widgets/mapo_network_image.dart';
import '../../../../core/services/plan_categories.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/mapo_data_service.dart';
import '../../../../shared/widgets/mapo_logo.dart';
import '../feed_home_tab_request.dart';
import '../widgets/experience_feed_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.loader, this.cardBuilder});
  final Future<List<Map<String, dynamic>>> Function(
    int offset,
    int limit,
    String category,
  )?
  loader;
  final Widget Function(BuildContext, Map<String, dynamic>)? cardBuilder;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _experiences = [];

  bool _isLoading = false;
  bool _hasMore = true;
  bool _loadFailed = false;

  int _currentPage = 0;
  int _loadGeneration = 0;
  String _selectedCategory = 'Todos';

  static const _categories = [
    ('Todos', Icons.explore_rounded),
    ('Aventura', Icons.landscape_rounded),
    ('Cultura', Icons.palette_rounded),
    ('Gastronomía', Icons.local_cafe_rounded),
    ('Naturaleza', Icons.park_outlined),
    ('Bienestar', Icons.spa_outlined),
    ('Deporte', Icons.sports_soccer),
    ('Arte', Icons.brush_outlined),
    ('Música', Icons.music_note_outlined),
    ('Nocturno', Icons.nightlife),
    ('Familia', Icons.family_restroom),
    ('Talleres', Icons.handyman_outlined),
    ('Rural', Icons.cottage_outlined),
    ('Historia', Icons.account_balance),
    ('Otro', Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    feedHomeTabRequest.addListener(_onHomeTabSelected);

    _loadNextPage();
  }

  Future<void> _onHomeTabSelected() async {
    if (_scrollController.hasClients && _scrollController.position.pixels > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) await _refreshFeed();
  }

  @override
  void dispose() {
    feedHomeTabRequest.removeListener(_onHomeTabSelected);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    const threshold = 1400.0;

    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final generation = _loadGeneration;

    try {
      final newExperiences = await _fetchExperiences(
        page: _currentPage,
        limit: _pageSize,
      );

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _experiences.addAll(newExperiences);

        _currentPage++;

        if (newExperiences.length < _pageSize) {
          _hasMore = false;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final item in newExperiences.take(3)) {
          final images = List<String>.from(item['images'] as List? ?? []);
          if (images.isNotEmpty && images.first.isNotEmpty) {
            precacheImage(
              ResizeImage(mapoImageProvider(images.first), width: 900),
              context,
              onError: (_, _) {},
            );
          }
        }
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExperiences({
    required int page,
    required int limit,
  }) async {
    if (widget.loader != null) {
      return widget.loader!(page * limit, limit, _selectedCategory);
    }
    return MapoDataService.fetchExperiences(
      offset: page * limit,
      limit: limit,
      category: _selectedCategory,
    );
  }

  void _selectCategory(String value) {
    setState(() => _selectedCategory = value);
    _refreshFeed();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        key: const PageStorageKey('experience-feed'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(1400),
        addRepaintBoundaries: false,
        padding: const EdgeInsets.only(bottom: 130),
        itemCount: _experiences.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) return const _FeedHeader();
          if (index == 1) {
            return SizedBox(
              height: 55,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final category = _categories[i];
                  return ChoiceChip(
                    label: Text(
                      PlanCategories.labels[category.$1] ?? category.$1,
                    ),
                    avatar: Icon(category.$2, size: 17),
                    selected: _selectedCategory == category.$1,
                    showCheckmark: false,
                    onSelected: (_) => _selectCategory(category.$1),
                  );
                },
              ),
            );
          }
          final planIndex = index - 2;
          if (planIndex < _experiences.length) {
            final plan = _experiences[planIndex];
            return Padding(
              key: ValueKey(plan['id']),
              padding: const EdgeInsets.only(top: 20),
              child:
                  widget.cardBuilder?.call(context, plan) ??
                  ExperienceFeedCard(experience: plan),
            );
          }
          if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_loadFailed) {
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Text('No pudimos cargar los planes.'),
                  TextButton(
                    onPressed: _loadNextPage,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (_experiences.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Todavía no hay planes de esta categoría.',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (_hasMore) {
            return Center(
              child: TextButton(
                onPressed: _loadNextPage,
                child: const Text('Cargar más planes'),
              ),
            );
          }
          return const SizedBox(height: 20);
        },
      ),
    ),
  );

  Future<void> _refreshFeed() async {
    _loadGeneration++;
    setState(() {
      _experiences.clear();
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
    });

    await _loadNextPage();
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(child: Center(child: const MapoLogo(width: 70))),
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.star_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
