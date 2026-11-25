import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../constants/env.dart';

abstract final class MediaService {
  static Future<String?> pickAndUpload() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 3 * 1024 * 1024) {
      throw StateError(
        'La foto es demasiado grande. Elige otra de menos de 3 MB.',
      );
    }
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Inicia sesión para subir fotos');
    final data = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final response =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 35),
          ),
        ).post(
          '${AppEnvironment.supabaseUrl}/api/media',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
    return response.data['url'] as String;
  }
}
