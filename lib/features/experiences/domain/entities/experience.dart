class Experience {
  const Experience({
    required this.id,
    required this.organizationId,
    required this.createdBy,
    required this.categoryId,
    required this.title,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.meetingPoint,
    required this.durationMinutes,
    required this.minimumPeople,
    required this.maximumPeople,
    required this.minimumAge,
    required this.instantBooking,
    required this.privateExperience,
    required this.wheelchairAccessible,
    required this.petsAllowed,
    required this.difficultyId,
    required this.statusId,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String createdBy;
  final String categoryId;

  final String title;
  final String slug;
  final String shortDescription;
  final String description;

  final String meetingPoint;

  final int durationMinutes;
  final int minimumPeople;
  final int maximumPeople;

  final int? minimumAge;

  final bool instantBooking;
  final bool privateExperience;
  final bool wheelchairAccessible;
  final bool petsAllowed;

  final String? difficultyId;

  final String statusId;

  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
