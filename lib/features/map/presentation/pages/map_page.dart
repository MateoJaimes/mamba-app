import '../../../../core/services/plan_categories.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../../core/services/currency_service.dart';
import 'dart:async';

import '../../../../shared/widgets/mapo_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/env.dart';
import '../../../../core/services/mapo_data_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _medellin = LatLng(6.2442, -75.5812);
  static const _mapExperienceLimit = 40;
  final MapController _mapController = MapController();
  Timer? _zoomRequestTimer;
  double _pendingZoomDelta = 0;
  String? _selectedExperienceId;
  String _selectedCategory = 'Todos';
  List<Map<String, dynamic>> _experiences = [];
  bool _failed = false;

  static final _categories = ['Todos', ...PlanCategories.labels.keys];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final experiences = await MapoDataService.fetchExperiences(
        limit: _mapExperienceLimit,
      );
      if (mounted) {
        setState(() {
          _experiences = experiences.where(_hasMapCoordinates).toList();
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _centerPlans() {
    final points = _experiences
        .where(
          (e) =>
              _selectedCategory == 'Todos' ||
              PlanCategories.of(e).contains(_selectedCategory),
        )
        .map(
          (e) => LatLng(
            (e['latitude'] as num).toDouble(),
            (e['longitude'] as num).toDouble(),
          ),
        )
        .toList();
    _mapController.rotate(0);
    if (points.length > 1) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(90, 160, 90, 240),
          maxZoom: 14,
        ),
      );
    } else if (points.isNotEmpty) {
      _mapController.move(points.first, 14);
    } else {
      _mapController.move(_medellin, 12.5);
    }
  }

  bool _hasMapCoordinates(Map<String, dynamic> experience) {
    final latitude = experience['latitude'];
    final longitude = experience['longitude'];
    if (latitude is! num || longitude is! num) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  @override
  void dispose() {
    _zoomRequestTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allExperiences = _experiences;
    final experiences = allExperiences.where((experience) {
      return _selectedCategory == 'Todos' ||
          PlanCategories.of(experience).contains(_selectedCategory);
    }).toList();
    Map<String, dynamic>? selected;
    if (_selectedExperienceId != null) {
      for (final item in allExperiences) {
        if (item['id'] == _selectedExperienceId) {
          selected = item;
          break;
        }
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _medellin,
                initialZoom: 12.5,
                minZoom: 9,
                maxZoom: 17,
                onTap: (_, _) {
                  if (_selectedExperienceId != null) {
                    setState(() => _selectedExperienceId = null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: AppEnvironment.mapTileUrl,
                  userAgentPackageName: 'com.mamba.mamba_app',
                  maxNativeZoom: 16,
                  keepBuffer: 1,
                  panBuffer: 0,
                ),
                MarkerLayer(
                  markers: experiences.map((experience) {
                    final id = experience['id'] as String;
                    final isSelected = id == _selectedExperienceId;
                    final latitude = experience['latitude'] as num;
                    final longitude = experience['longitude'] as num;
                    return Marker(
                      point: LatLng(latitude.toDouble(), longitude.toDouble()),
                      width: 160,
                      height: 88,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedExperienceId = id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xED162642),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${experience['title']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF0E1B34)
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${experience['experience_rating']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? const Color(0xFF0E1B34)
                                      : AppColors.textSecondary,
                                ),
                              ),
                              MoneyText(
                                amount: CurrencyService.amount(experience),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: isSelected
                                      ? const Color(0xFF0E1B34)
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GlassPanel(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explora el mapa',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Medellín · ${experiences.length} planes',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MapIconButton(
                      tooltip: 'Centrar planes',
                      icon: Icons.my_location_rounded,
                      onPressed: _centerPlans,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() {
                          _selectedCategory = category;
                          final categoryExperiences = allExperiences.where(
                            (item) =>
                                category == 'Todos' ||
                                PlanCategories.of(item).contains(category),
                          );
                          if (_selectedExperienceId != null &&
                              !categoryExperiences.any(
                                (item) => item['id'] == _selectedExperienceId,
                              )) {
                            _selectedExperienceId = null;
                          }
                        }),
                        backgroundColor: const Color(0xDD162642),
                        selectedColor: AppColors.primary,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0E1B34)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: selected == null ? 110 : 220,
            child: Column(
              children: [
                _MapIconButton(
                  tooltip: 'Orientar al norte',
                  icon: Icons.explore_outlined,
                  onPressed: () => _mapController.rotate(0),
                ),
                const SizedBox(height: 7),
                _MapIconButton(
                  tooltip: 'Acercar',
                  icon: Icons.add_rounded,
                  onPressed: () => _changeZoom(.5),
                ),
                const SizedBox(height: 7),
                _MapIconButton(
                  tooltip: 'Alejar',
                  icon: Icons.remove_rounded,
                  onPressed: () => _changeZoom(-.5),
                ),
              ],
            ),
          ),
          if (selected != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 104,
              child: SafeArea(
                top: false,
                child: _SelectedExperienceCard(experience: selected),
              ),
            )
          else
            Positioned(
              left: 16,
              bottom: 112,
              child: _GlassPanel(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Toca un plan para verlo',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 78,
            bottom: selected == null ? 84 : 202,
            child: _GlassPanel(
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          if (_failed)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: Material(
                child: TextButton(
                  onPressed: _load,
                  child: const Text('No pudimos cargar los planes. Reintentar'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _changeZoom(double delta) {
    _pendingZoomDelta += delta;
    _zoomRequestTimer?.cancel();
    _zoomRequestTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted || !_mapController.camera.zoom.isFinite) return;
      final camera = _mapController.camera;
      final nextZoom = (camera.zoom + _pendingZoomDelta)
          .clamp(9.0, 17.0)
          .toDouble();
      _pendingZoomDelta = 0;
      if (nextZoom != camera.zoom) _mapController.move(camera.center, nextZoom);
    });
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xF2192B49),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xDD162642),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary),
    ),
  );
}

class _SelectedExperienceCard extends StatelessWidget {
  const _SelectedExperienceCard({required this.experience});
  final Map<String, dynamic> experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/experience/${experience['id']}'),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: .42)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MapoNetworkImage(
                  imageUrl: (experience['images'] as List<String>).first,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) => const SizedBox(
                    width: 86,
                    height: 86,
                    child: ColoredBox(color: Color(0xFF233654)),
                  ),
                  errorWidget: (_, _, _) => const SizedBox(
                    width: 86,
                    height: 86,
                    child: Icon(Icons.landscape_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      experience['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      experience['location'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${experience['experience_rating']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    MoneyText(
                      amount: CurrencyService.amount(experience),
                      prefix: 'Desde ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
