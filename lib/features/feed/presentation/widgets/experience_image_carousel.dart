import 'package:flutter/material.dart';
import '../../../../shared/widgets/mapo_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reviews/domain/colombian_rating.dart';
import '../../../reviews/presentation/widgets/colombian_rating_badge.dart';

class ExperienceImageCarousel extends StatefulWidget {
  const ExperienceImageCarousel({
    super.key,
    required this.images,
    this.onTap,
    this.ratingLabel,
    this.imageProviderBuilder,
  });

  final List<String> images;
  final VoidCallback? onTap;
  final String? ratingLabel;
  final ImageProvider Function(String)? imageProviderBuilder;

  @override
  State<ExperienceImageCarousel> createState() =>
      _ExperienceImageCarouselState();
}

class _ExperienceImageCarouselState extends State<ExperienceImageCarousel> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (page) {
                  if (page + 1 < widget.images.length) {
                    precacheImage(
                      ResizeImage(
                        mapoImageProvider(widget.images[page + 1]),
                        width: 900,
                      ),
                      context,
                      onError: (_, _) {},
                    );
                  }
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return Image(
                    image:
                        widget.imageProviderBuilder?.call(
                          widget.images[index],
                        ) ??
                        ResizeImage(
                          mapoImageProvider(widget.images[index]),
                          width: 900,
                        ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const ColoredBox(
                            color: AppColors.surfaceRaised,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.surfaceRaised,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (widget.ratingLabel != null)
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: ColombianRatingBadge(
                    label: widget.ratingLabel!,
                    target: ColombianRatingTarget.experience,
                    prominent: true,
                    overImage: true,
                  ),
                ),

              if (widget.images.length > 1)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (index) {
                      final selected = index == _currentPage;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 8 : 6,
                        height: selected ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
