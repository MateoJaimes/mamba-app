class ExperienceLocation {
  const ExperienceLocation({
    required this.id,
    required this.experienceId,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.positionOrder,
  });

  final String id;

  final String experienceId;

  final String? title;

  final double latitude;

  final double longitude;

  final String? address;

  final int positionOrder;
}
