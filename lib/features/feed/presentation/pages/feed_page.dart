import 'package:flutter/material.dart';

import '../../../../core/widgets/scroll_edge_blur.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../hosts/data/demo_host_catalog.dart';
import '../feed_home_tab_request.dart';
import '../widgets/experience_feed_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _experiences = [];

  bool _isLoading = false;
  bool _hasMore = true;

  int _currentPage = 0;
  int _loadGeneration = 0;
  String _selectedCategory = 'Todos';

  static const _categories = [
    ('Todos', Icons.explore_rounded),
    ('Aventura', Icons.landscape_rounded),
    ('Cultura', Icons.palette_rounded),
    ('Gastronomía', Icons.local_cafe_rounded),
  ];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    feedHomeTabRequest.addListener(_onHomeTabSelected);

    _loadNextPage();
  }

  Future<void> _onHomeTabSelected() async {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels > 0) {
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

    const threshold = 600.0;

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
    await Future.delayed(const Duration(milliseconds: 700));

    final start = page * limit;
    final end = start + limit;

    if (start >= DemoHostCatalog.experiences.length) {
      return [];
    }

    return DemoHostCatalog.experiences.sublist(
      start,
      end > DemoHostCatalog.experiences.length
          ? DemoHostCatalog.experiences.length
          : end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleExperiences = _selectedCategory == 'Todos'
        ? _experiences
        : _experiences
              .where(
                (experience) => experience['category'] == _selectedCategory,
              )
              .toList();

    return Scaffold(
      body: ScrollEdgeBlur(
        controller: _scrollController,
        bottomExtent: 140,
        child: RefreshIndicator(
          onRefresh: _refreshFeed,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: const _FeedHeader()),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 55,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final selected = _selectedCategory == category.$1;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(category.$2, size: 17),
                        label: Text(category.$1),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = category.$1),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary.withValues(alpha: .22),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary.withValues(alpha: .65)
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_experiences.isEmpty && _isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleExperiences.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.travel_explore_rounded,
                            size: 46,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Todavía no hay planes de esta categoría.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedCategory = 'Todos'),
                            child: const Text('Ver todos los planes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: SliverList.separated(
                    itemCount: visibleExperiences.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 24),
                    itemBuilder: (context, index) => ExperienceFeedCard(
                      experience: visibleExperiences[index],
                    ),
                  ),
                ),
              if (_isLoading && _experiences.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Text(
                    'MAMBA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 3.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: () => _showNotifications(context),
                icon: const Icon(Icons.star_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 22),
              const Icon(
                Icons.star_rounded,
                size: 38,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Notificaciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí verás novedades de tus planes y anfitriones.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Todavía no tienes novedades.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
