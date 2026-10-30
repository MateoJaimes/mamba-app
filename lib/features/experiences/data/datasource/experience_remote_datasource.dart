import '../dto/experience_dto.dart';

abstract interface class ExperienceRemoteDataSource {
  Future<List<ExperienceDto>> getExperiences();

  Future<ExperienceDto> getExperience(String id);
}
