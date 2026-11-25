import 'account_service.dart';

abstract final class HostPlanService {
  static Future<List<Map<String, dynamic>>> load(String hostId) async =>
      await AccountService.client
          .from('experiences')
          .select('*,experience_images(image_url,position)')
          .eq('host_profile_id', hostId)
          .order('created_at', ascending: false);
  static Future<void> changeStatus(
    Map<String, dynamic> plan,
    String status,
  ) async {
    final photos = List<Map<String, dynamic>>.from(
      plan['experience_images'] as List? ?? [],
    )..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    await AccountService.action('save_experience', {
      ...plan,
      'status': status,
      'categories': plan['categories'] ?? [plan['category']],
      'images': photos.map((p) => p['image_url']).toList(),
    });
  }
}
