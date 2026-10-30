import '../../domain/entities/experience.dart';
import '../dto/experience_dto.dart';

extension ExperienceMapper on ExperienceDto {
  Experience toEntity() {
    return Experience(
      id: id,
      organizationId: organizationId,
      createdBy: createdBy,
      categoryId: categoryId,
      title: title,
      slug: slug,
      shortDescription: shortDescription,
      description: description,
      meetingPoint: meetingPoint,
      durationMinutes: durationMinutes,
      minimumPeople: minimumPeople,
      maximumPeople: maximumPeople,
      minimumAge: minimumAge,
      instantBooking: instantBooking,
      privateExperience: privateExperience,
      wheelchairAccessible: wheelchairAccessible,
      petsAllowed: petsAllowed,
      difficultyId: difficultyId,
      statusId: statusId,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
