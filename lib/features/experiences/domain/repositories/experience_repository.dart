import '../entities/experience.dart';

abstract interface class ExperienceRepository {
  Future<List<Experience>> getExperiences();

  Future<Experience> getExperience(String id);
}
