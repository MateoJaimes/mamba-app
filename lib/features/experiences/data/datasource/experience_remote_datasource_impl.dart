import '../dto/experience_dto.dart';
import 'experience_remote_datasource.dart';

class ExperienceRemoteDataSourceImpl implements ExperienceRemoteDataSource {
  @override
  Future<List<ExperienceDto>> getExperiences() async {
    return [];
  }

  @override
  Future<ExperienceDto> getExperience(String id) {
    throw UnimplementedError();
  }
}
