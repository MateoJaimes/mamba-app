import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../hosts/data/demo_host_catalog.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _medellin = LatLng(6.2442, -75.5812);
  final MapController _mapController = MapController();
  String? _selectedExperienceId;
  String _selectedCategory = 'Todos';

  static const _categories = ['Todos', 'Aventura', 'Cultura', 'Gastronomía'];

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experiences = DemoHostCatalog.experiences.where((experience) {
      return _selectedCategory == 'Todos' ||
          experience['category'] == _selectedCategory;
    }).toList();
    final selected = _selectedExperienceId == null
        ? null
        : DemoHostCatalog.experienceById(_selectedExperienceId!);

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
                maxZoom: 18,
                onTap: (_, _) => setState(() => _selectedExperienceId = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mamba.mamba_app',
                  maxNativeZoom: 18,
                  panBuffer: 1,
                ),
                MarkerLayer(
                  markers: experiences.map((experience) {
                    final id = experience['id'] as String;
                    final isSelected = id == _selectedExperienceId;
                    final price = (experience['price'] as String)
                        .replaceAll(r'$', '')
                        .replaceAll('.000', 'k');
                    return Marker(
                      point: LatLng(
                        (experience['latitude'] as num).toDouble(),
                        (experience['longitude'] as num).toDouble(),
                      ),
                      width: 90,
                      height: 48,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedExperienceId = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xED171F1B),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: AppColors.primary,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 15,
                                color: isSelected
                                    ? const Color(0xFF06251A)
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                price,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF06251A)
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
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
                      tooltip: 'Volver a Medellín',
                      icon: Icons.my_location_rounded,
                      onPressed: () => _mapController.move(_medellin, 12.5),
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
                          final categoryExperiences = DemoHostCatalog
                              .experiences
                              .where(
                                (item) =>
                                    category == 'Todos' ||
                                    item['category'] == category,
                              );
                          if (_selectedExperienceId != null &&
                              !categoryExperiences.any(
                                (item) => item['id'] == _selectedExperienceId,
                              )) {
                            _selectedExperienceId = null;
                          }
                        }),
                        backgroundColor: const Color(0xDD171F1B),
                        selectedColor: AppColors.primary,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF06251A)
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
                  tooltip: 'Acercar',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom + 1).clamp(9, 18),
                    );
                  },
                ),
                const SizedBox(height: 7),
                _MapIconButton(
                  tooltip: 'Alejar',
                  icon: Icons.remove_rounded,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom - 1).clamp(9, 18),
                    );
                  },
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
                '© Stadia Maps · © OpenMapTiles · © OpenStreetMap',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xF21A211E),
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
    color: const Color(0xDD171F1B),
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
                child: CachedNetworkImage(
                  imageUrl: (experience['images'] as List<String>).first,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) => const SizedBox(
                    width: 86,
                    height: 86,
                    child: ColoredBox(color: Color(0xFF202824)),
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
                      '${experience['experience_rating']} · Desde ${experience['price']}',
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
