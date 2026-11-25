import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/mapo_data_service.dart';

/// Server-backed bookings; legacy device drafts are only readable offline.
abstract final class LocalBookingStore {
  static const _storageKey = 'mapo.local_booking_intents.v1';
  static final changes = ValueNotifier<List<Map<String, dynamic>>>(const []);

  static Future<List<Map<String, dynamic>>> getAll() async {
    if (MapoDataService.hasSignedInUser) {
      final bookings = await MapoDataService.fetchBookings();
      changes.value = List.unmodifiable(bookings);
      return bookings;
    }
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return [];
    try {
      final bookings = (jsonDecode(encoded) as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      changes.value = bookings;
      return bookings;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  static Future<void> create({
    required Map<String, dynamic> experience,
    required DateTime date,
    required int adults,
    required int minors,
    required bool minorsSupervisionConfirmed,
    required bool minimumAgeConfirmed,
  }) async {
    if (!MapoDataService.hasSignedInUser) {
      throw StateError(
        'Inicia sesión y conéctate a internet para confirmar tu inscripción.',
      );
    }
    final booking = await MapoDataService.createBooking(
      experience: experience,
      date: date,
      adults: adults,
      minors: minors,
      minorsSupervisionConfirmed: minorsSupervisionConfirmed,
      minimumAgeConfirmed: minimumAgeConfirmed,
    );
    // Saving succeeded. A failed follow-up read must not invite a duplicate retry.
    try {
      await getAll();
    } catch (_) {
      changes.value = List.unmodifiable([
        ...changes.value.where(
          (row) =>
              row['user_id'] == MapoDataService.currentUserId &&
              row['id'] != booking['id'],
        ),
        {
          ...booking,
          'experience_title': experience['title'],
          'provider_id': experience['provider_id'],
          'provider_name': experience['provider'],
          'date': booking['booking_date'],
          'guests': adults + minors,
          'image': (experience['images'] as List).first,
        },
      ]);
    }
  }
}
