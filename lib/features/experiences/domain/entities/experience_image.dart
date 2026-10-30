class ExperienceImage {
  const ExperienceImage({
    required this.id,
    required this.experienceId,
    required this.imageUrl,
    required this.altText,
    required this.isCover,
    required this.displayOrder,
  });

  final String id;
  final String experienceId;

  final String imageUrl;

  final String? altText;

  final bool isCover;

  final int displayOrder;
}
