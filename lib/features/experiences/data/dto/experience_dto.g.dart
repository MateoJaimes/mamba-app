// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experience_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExperienceDto _$ExperienceDtoFromJson(Map<String, dynamic> json) =>
    ExperienceDto(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      createdBy: json['created_by'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      shortDescription: json['short_description'] as String,
      description: json['description'] as String,
      meetingPoint: json['meeting_point'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      minimumPeople: (json['minimum_people'] as num).toInt(),
      maximumPeople: (json['maximum_people'] as num).toInt(),
      minimumAge: (json['minimum_age'] as num?)?.toInt(),
      instantBooking: json['instant_booking'] as bool,
      privateExperience: json['private_experience'] as bool,
      wheelchairAccessible: json['wheelchair_accessible'] as bool,
      petsAllowed: json['pets_allowed'] as bool,
      difficultyId: json['difficulty_id'] as String?,
      statusId: json['status_id'] as String,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ExperienceDtoToJson(ExperienceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organization_id': instance.organizationId,
      'created_by': instance.createdBy,
      'category_id': instance.categoryId,
      'title': instance.title,
      'slug': instance.slug,
      'short_description': instance.shortDescription,
      'description': instance.description,
      'meeting_point': instance.meetingPoint,
      'duration_minutes': instance.durationMinutes,
      'minimum_people': instance.minimumPeople,
      'maximum_people': instance.maximumPeople,
      'minimum_age': instance.minimumAge,
      'instant_booking': instance.instantBooking,
      'private_experience': instance.privateExperience,
      'wheelchair_accessible': instance.wheelchairAccessible,
      'pets_allowed': instance.petsAllowed,
      'difficulty_id': instance.difficultyId,
      'status_id': instance.statusId,
      'published_at': instance.publishedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
