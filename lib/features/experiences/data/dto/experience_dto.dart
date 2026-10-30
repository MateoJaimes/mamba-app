import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'experience_dto.g.dart';

@JsonSerializable()
class ExperienceDto extends Equatable {
  const ExperienceDto({
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
    this.minimumAge,
    required this.instantBooking,
    required this.privateExperience,
    required this.wheelchairAccessible,
    required this.petsAllowed,
    this.difficultyId,
    required this.statusId,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExperienceDto.fromJson(Map<String, dynamic> json) =>
      _$ExperienceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExperienceDtoToJson(this);

  final String id;

  @JsonKey(name: 'organization_id')
  final String organizationId;

  @JsonKey(name: 'created_by')
  final String createdBy;

  @JsonKey(name: 'category_id')
  final String categoryId;

  final String title;
  final String slug;

  @JsonKey(name: 'short_description')
  final String shortDescription;

  final String description;

  @JsonKey(name: 'meeting_point')
  final String meetingPoint;

  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;

  @JsonKey(name: 'minimum_people')
  final int minimumPeople;

  @JsonKey(name: 'maximum_people')
  final int maximumPeople;

  @JsonKey(name: 'minimum_age')
  final int? minimumAge;

  @JsonKey(name: 'instant_booking')
  final bool instantBooking;

  @JsonKey(name: 'private_experience')
  final bool privateExperience;

  @JsonKey(name: 'wheelchair_accessible')
  final bool wheelchairAccessible;

  @JsonKey(name: 'pets_allowed')
  final bool petsAllowed;

  @JsonKey(name: 'difficulty_id')
  final String? difficultyId;

  @JsonKey(name: 'status_id')
  final String statusId;

  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    organizationId,
    createdBy,
    categoryId,
    title,
    slug,
    shortDescription,
    description,
    meetingPoint,
    durationMinutes,
    minimumPeople,
    maximumPeople,
    minimumAge,
    instantBooking,
    privateExperience,
    wheelchairAccessible,
    petsAllowed,
    difficultyId,
    statusId,
    publishedAt,
    createdAt,
    updatedAt,
  ];
}
