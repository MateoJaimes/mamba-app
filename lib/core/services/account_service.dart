import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:flutter/services.dart' show PlatformException;

class AccountSnapshot {
  const AccountSnapshot(
    this.profile,
    this.roles,
    this.application,
    this.host, {
    this.photos = const [],
  });
  final Map<String, dynamic> profile;
  final Set<String> roles;
  final Map<String, dynamic>? application;
  final Map<String, dynamic>? host;
  final List<Map<String, dynamic>> photos;
  bool get isAdmin => roles.contains('admin');
  bool get canHost => roles.contains('host') && host?['approved_at'] != null;
}

abstract final class AccountService {
  static SupabaseClient get client => Supabase.instance.client;
  static String get userId => client.auth.currentUser!.id;

  static Future<AccountSnapshot> load() async {
    final results = await Future.wait<dynamic>([
      Future(
        () async =>
            await client.from('profiles').select().eq('id', userId).single(),
      ),
      Future(
        () async => await client
            .from('user_roles')
            .select('role')
            .eq('user_id', userId),
      ),
      Future(
        () async => await client
            .from('host_applications')
            .select()
            .eq('user_id', userId)
            .maybeSingle(),
      ),
      Future(
        () async => await client
            .from('host_profiles')
            .select()
            .eq('owner_id', userId)
            .maybeSingle(),
      ),
      Future(
        () async => await client
            .from('profile_photos')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false),
      ),
    ]);
    return AccountSnapshot(
      Map<String, dynamic>.from(results[0] as Map),
      (results[1] as List).map((r) => r['role'] as String).toSet(),
      results[2] == null ? null : Map<String, dynamic>.from(results[2] as Map),
      results[3] == null ? null : Map<String, dynamic>.from(results[3] as Map),
      photos: (results[4] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(),
    );
  }

  static Future<void> action(
    String action,
    Map<String, dynamic> payload,
  ) async {
    await client.rpc(
      'host_action',
      params: {'action': action, 'payload': payload},
    );
  }

  static String error(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is PlatformException) {
      return 'No pudimos abrir tus fotos. Revisa el permiso de fotos de MAPO en los ajustes del dispositivo.';
    }
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    }
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return 'Este registro ya existe. Si es una reseña, ya calificaste esa inscripción; si es un usuario, elige otro.';
      }
      if (error.code == '23514' || error.code == '22P02') {
        return 'Revisa los datos: cantidades, precio, ubicación y edades.';
      }
      if (error.code == 'P0001') {
        if (error.message.contains('not enough places')) {
          return 'No quedan suficientes cupos para esa fecha. Elige otra fecha o menos participantes.';
        }
        if (error.message.contains('outside the allowed range')) {
          return 'Revisa la fecha y la cantidad de participantes.';
        }
        if (error.message.contains('Experience is not available')) {
          return 'Este plan ya no está disponible.';
        }
        if (error.message.contains('Minimum age')) {
          return 'Confirma que los participantes cumplen la edad mínima.';
        }
        if (error.message.contains('Adult supervision')) {
          return 'Los menores deben asistir con un adulto responsable.';
        }
        return error.message;
      }
    }
    return 'No pudimos completar la operación. Revisa la conexión e inténtalo de nuevo.';
  }
}
