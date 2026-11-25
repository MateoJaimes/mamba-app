import 'package:flutter/material.dart';
import 'mapo_network_image.dart';
import '../../core/theme/app_colors.dart';

class EditableProfileHero extends StatelessWidget {
  const EditableProfileHero({
    super.key,
    this.avatar,
    this.cover,
    required this.onAvatar,
    required this.onCover,
    required this.onSettings,
    this.busy = false,
    this.title = 'Mi perfil',
  });
  final String? avatar, cover;
  final VoidCallback onAvatar, onCover, onSettings;
  final bool busy;
  final String title;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 338,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 280,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: cover?.isNotEmpty == true
                ? MapoNetworkImage(
                    imageUrl: cover!,
                    fit: BoxFit.cover,
                    memCacheWidth: 1000,
                    errorWidget: (_, _, _) => const _CoverPlaceholder(),
                  )
                : const _CoverPlaceholder(),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 280,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x88000000),
                    Colors.transparent,
                    Color(0x99000000),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Configuración',
                    onPressed: onSettings,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 18,
          top: 222,
          child: IconButton.filledTonal(
            tooltip: 'Cambiar portada',
            onPressed: busy ? null : onCover,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ),
        // The whole avatar and its camera stay inside this box's hit-test bounds.
        Positioned(
          top: 216,
          left: 22,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 3),
                    ),
                    child: GestureDetector(
                      onTap: busy ? null : onAvatar,
                      child: CircleAvatar(
                        backgroundColor: AppColors.surfaceRaised,
                        backgroundImage: avatar?.isNotEmpty == true
                            ? mapoImageProvider(avatar!)
                            : null,
                        child: avatar?.isNotEmpty == true
                            ? null
                            : const Icon(
                                Icons.person_outline,
                                size: 46,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    tooltip: 'Cambiar foto de perfil',
                    onPressed: busy ? null : onAvatar,
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF294864), Color(0xFF132541)],
      ),
    ),
    child: Center(
      child: Icon(Icons.landscape_outlined, size: 72, color: Color(0x5559CFC4)),
    ),
  );
}
