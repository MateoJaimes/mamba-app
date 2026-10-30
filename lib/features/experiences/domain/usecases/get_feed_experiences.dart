import '../entities/experience.dart';
import '../repositories/experience_repository.dart';

class GetFeedExperiences {
  const GetFeedExperiences(this._repository);

  final ExperienceRepository _repository;

  Future<List<Experience>> call() {
    return _repository.getExperiences();
  }
}
