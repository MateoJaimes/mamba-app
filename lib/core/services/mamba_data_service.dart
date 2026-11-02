import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';
import '../../features/hosts/data/demo_host_catalog.dart';

/// Supabase-backed reads and writes used by the current MAMBA screens.
/// Demo content remains available before Auth is configured or signed in.
abstract final class MambaDataService {
  static bool get isReady => AppEnvironment.hasSupabaseConfig;
  static bool get hasSignedInUser => _signedIn;
  static String? get currentUserId => _signedIn ? _client.auth.currentUser?.id : null;
  static SupabaseClient get _client => Supabase.instance.client;
  static bool get _signedIn => isReady && _client.auth.currentUser != null;

  static Future<List<Map<String, dynamic>>> fetchExperiences({
    int offset = 0,
    int limit = 20,
  }) async {
    if (!isReady) return _demoExperiences(offset, limit);
    try {
      final rows = await _client
          .from('experience_feed')
          .select()
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (rows as List).map((row) => _experienceMap(
        Map<String, dynamic>.from(row as Map),
      )).toList();
    } catch (_) {
      return _demoExperiences(offset, limit);
    }
  }

  static Future<Map<String, dynamic>?> fetchExperience(String id) async {
    if (!isReady) return DemoHostCatalog.experienceById(id);
    try {
      final row = await _client.from('experience_feed').select().eq('id', id).maybeSingle();
      if (row == null) return DemoHostCatalog.experienceById(id);
      final experience = _experienceMap(row);
      experience['host_profile'] = await fetchHost('${row['provider_id']}');
      return experience;
    } catch (_) {
      return DemoHostCatalog.experienceById(id);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHosts() async {
    if (!isReady) return DemoHostCatalog.hosts.map((e) => Map<String, dynamic>.from(e)).toList();
    try {
      final rows = await _client.from('host_public_profiles').select().order('name');
      return (rows as List).map((row) => _hostMap(Map<String, dynamic>.from(row as Map))).toList();
    } catch (_) {
      return DemoHostCatalog.hosts.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  static Future<Map<String, dynamic>?> fetchHost(String id) async {
    if (!isReady) {
      final host = DemoHostCatalog.hostById(id);
      return host == null ? null : Map<String, dynamic>.from(host);
    }
    try {
      final row = await _client.from('host_public_profiles').select().eq('id', id).maybeSingle();
      if (row != null) return _hostMap(row);
    } catch (_) {}
    final host = DemoHostCatalog.hostById(id);
    return host == null ? null : Map<String, dynamic>.from(host);
  }

  static Future<List<Map<String, dynamic>>> fetchExperiencesForHost(String id) async {
    final rows = await fetchExperiences(limit: 100);
    final matching = rows.where((row) => row['provider_id'] == id).toList();
    if (matching.isNotEmpty || isReady) return matching;
    return DemoHostCatalog.experiencesByHost(id);
  }

  static Future<List<Map<String, String>>> fetchReviewsForHost(String id) async {
    if (isReady) {
      try {
        final rows = await _client.from('review_feed').select().eq('host_profile_id', id).order('created_at', ascending: false);
        return (rows as List).map((raw) {
          final row = Map<String, dynamic>.from(raw as Map);
          return <String, String>{
            'author': '${row['author'] ?? 'Viajero'}',
            'experience': '${row['experience'] ?? 'Experiencia'}',
            'date': _relativeDate(row['created_at']),
            'rating': _hostRating(row['host_score']),
            'comment': '${row['comment'] ?? ''}',
          };
        }).toList();
      } catch (_) {}
    }
    return DemoHostCatalog.reviewsByHost(id);
  }

  static Future<List<Map<String, dynamic>>> fetchBookings() async {
    if (!_signedIn) return [];
    final rows = await _client.from('my_bookings').select().order('date');
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return {
        ...row,
        'experience_title': row['experience_title'],
        'provider_name': row['provider_name'],
        'price': _formatPrice(row['total_amount']),
        'image': row['image'] ?? '',
        'date': row['date'],
        'guests': row['guests'] ?? ((row['adults'] ?? 0) + (row['minors'] ?? 0)),
      };
    }).toList();
  }

  static Future<void> createBooking({
    required Map<String, dynamic> experience,
    required DateTime date,
    required int adults,
    required int minors,
    required bool minorsSupervisionConfirmed,
    required bool minimumAgeConfirmed,
  }) async {
    if (!_signedIn) throw StateError('Inicia sesión para solicitar una inscripción.');
    await _client.from('bookings').insert({
      'user_id': _client.auth.currentUser!.id,
      'experience_id': experience['id'],
      'booking_date': DateFormat('yyyy-MM-dd').format(date),
      'adults': adults,
      'minors': minors,
      'minors_supervision_confirmed': minorsSupervisionConfirmed,
      'minimum_age_confirmed': minimumAgeConfirmed,
    });
  }

  static Future<bool> toggleExperienceLike(String experienceId, bool liked) async {
    if (!_signedIn) return liked;
    if (liked) {
      await _client.from('experience_likes').delete().eq('user_id', _client.auth.currentUser!.id).eq('experience_id', experienceId);
      return false;
    }
    await _client.from('experience_likes').insert({'user_id': _client.auth.currentUser!.id, 'experience_id': experienceId});
    return true;
  }

  static Future<bool> toggleFavorite(String experienceId, bool saved) async {
    if (!_signedIn) return saved;
    if (saved) {
      await _client.from('favorites').delete().eq('user_id', _client.auth.currentUser!.id).eq('experience_id', experienceId);
      return false;
    }
    await _client.from('favorites').insert({'user_id': _client.auth.currentUser!.id, 'experience_id': experienceId});
    return true;
  }

  static Future<Map<String, dynamic>> addComment(
    String experienceId,
    String body,
  ) async {
    if (!_signedIn) throw StateError('Inicia sesión para comentar.');
    final row = await _client
        .from('experience_comments')
        .insert({
          'user_id': _client.auth.currentUser!.id,
          'experience_id': experienceId,
          'body': body,
        })
        .select('id,user_id,body,author_name,author_avatar_url,created_at')
        .single();
    return Map<String, dynamic>.from(row);
  }

  static Future<Map<String, dynamic>> updateComment(
    String commentId,
    String body,
  ) async {
    if (!_signedIn) throw StateError('Inicia sesión para editar comentarios.');
    final row = await _client
        .from('experience_comments')
        .update({'body': body})
        .eq('id', commentId)
        .eq('user_id', _client.auth.currentUser!.id)
        .select('id,user_id,body,author_name,author_avatar_url,created_at')
        .single();
    return Map<String, dynamic>.from(row);
  }

  static Future<void> deleteComment(String commentId) async {
    if (!_signedIn) throw StateError('Inicia sesión para eliminar comentarios.');
    await _client
        .from('experience_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', _client.auth.currentUser!.id);
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    if (!_signedIn) return const [];
    final rows = await _client.from('notifications').select()
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static Future<void> markNotificationRead(String notificationId) async {
    if (!_signedIn) return;
    await _client.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId).eq('user_id', _client.auth.currentUser!.id);
  }

  static Future<List<Map<String, dynamic>>> fetchComments(
    String experienceId,
  ) async {
    if (!isReady) return const [];
    try {
      final rows = await _client
          .from('experience_comments')
          .select('id,user_id,body,author_name,author_avatar_url,created_at')
          .eq('experience_id', experienceId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> isFollowingHost(String hostId) async {
    if (!_signedIn) return false;
    final row = await _client.from('host_follows').select('host_profile_id')
        .eq('follower_id', _client.auth.currentUser!.id).eq('host_profile_id', hostId).maybeSingle();
    return row != null;
  }

  static Future<bool> toggleHostFollow(String hostId, bool following) async {
    if (!_signedIn) return following;
    if (following) {
      await _client.from('host_follows').delete().eq('follower_id', _client.auth.currentUser!.id).eq('host_profile_id', hostId);
      return false;
    }
    await _client.from('host_follows').insert({'follower_id': _client.auth.currentUser!.id, 'host_profile_id': hostId});
    return true;
  }

  static List<Map<String, dynamic>> _demoExperiences(int offset, int limit) =>
      DemoHostCatalog.experiences.skip(offset).take(limit).toList();

  static Map<String, dynamic> _hostMap(Map<String, dynamic> row) => {
    ...row,
    'handle': _atHandle('${row['handle'] ?? ''}'),
    'avatar': row['avatar'] ?? '',
    'cover': row['cover'] ?? '',
    'location': row['location'] ?? '',
    'verified': '${row['verified'] ?? false}',
    'joined': row['joined'] ?? '',
    'reviews': '${row['reviews_count'] ?? 0}',
    'followers': '${row['followers_count'] ?? 0}',
    'host_rating': _hostRating(row['host_rating_score']),
  };

  static Map<String, dynamic> _experienceMap(Map<String, dynamic> row) {
    final score = (row['experience_rating_score'] as num?)?.round();
    final images = (row['images'] as List? ?? const []).map((e) => '$e').toList();
    return {
      ...row,
      'provider': row['provider'] ?? 'Anfitrión MAMBA',
      'price': _formatPrice(row['price_amount']),
      'duration': _formatDuration(row['duration_minutes']),
      'images': images.isEmpty ? <String>[''] : images,
      'max_people': row['max_people'] ?? 10,
      'minor_supervision_required': row['minors_supervision_required'] ?? false,
      'experience_rating': score == null ? 'Aún sin reseñas' : _experienceRating(score),
      'host_rating': _hostRating(row['host_rating_score']),
      'reviews': '${row['reviews_count'] ?? 0}',
      'is_liked_by_me': row['is_liked_by_me'] == true,
      'is_saved_by_me': row['is_saved_by_me'] == true,
    };
  }

  static String _formatPrice(Object? value) {
    final amount = (value as num?)?.round() ?? 0;
    return '\$${NumberFormat('#,###', 'es_CO').format(amount)}';
  }

  static String _formatDuration(Object? value) {
    final minutes = (value as num?)?.toInt() ?? 0;
    return minutes >= 60 ? '${minutes ~/ 60} horas' : '$minutes minutos';
  }

  static String _experienceRating(int? score) => switch (score) {
    1 => 'No fue lo mío', 2 => 'Buen parche', 3 => 'Súper parche',
    4 => 'Planazo', 5 => '¡Una chimba!', _ => 'Aún sin reseñas',
  };

  static String _hostRating(Object? raw) => switch ((raw as num?)?.round()) {
    1 => 'No volvería', 2 => 'Atención normal', 3 => 'Buen anfitrión',
    4 => 'Muy buena energía', 5 => 'Se lució', _ => 'Aún sin reseñas',
  };

  static String _atHandle(String handle) => handle.startsWith('@') ? handle : '@$handle';

  static String _relativeDate(Object? raw) {
    final date = DateTime.tryParse('$raw')?.toLocal();
    if (date == null) return '';
    final days = DateTime.now().difference(date).inDays;
    if (days < 1) return 'Hoy';
    if (days == 1) return 'Hace 1 día';
    if (days < 30) return 'Hace $days días';
    return 'Hace ${days ~/ 30} meses';
  }
}
