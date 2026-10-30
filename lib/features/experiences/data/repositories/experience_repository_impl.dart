import '../../domain/entities/experience.dart';
import '../../domain/repositories/experience_repository.dart';

import '../datasource/experience_remote_datasource.dart';
import '../mapper/experience_mapper.dart';

class ExperienceRepositoryImpl implements ExperienceRepository {
  const ExperienceRepositoryImpl(this._remote);

  final ExperienceRemoteDataSource _remote;

  @override
  Future<List<Experience>> getExperiences() async {
    final result = await _remote.getExperiences();

    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Experience> getExperience(String id) async {
    final dto = await _remote.getExperience(id);

    return dto.toEntity();
  }
}
