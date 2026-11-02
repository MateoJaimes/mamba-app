import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/mamba_data_service.dart';

/// Device-local prototype storage. Replace with an authenticated backend before
/// treating these booking requests as confirmed reservations.
abstract final class LocalBookingStore {
  static const _storageKey = 'mamba.local_booking_intents.v1';
  static const _uuid = Uuid();
  static final changes = ValueNotifier<List<Map<String, dynamic>>>(const []);

  static Future<List<Map<String, dynamic>>> getAll() async {
    if (MambaDataService.hasSignedInUser) {
      final bookings = await MambaDataService.fetchBookings();
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
    if (MambaDataService.hasSignedInUser) {
      await MambaDataService.createBooking(
        experience: experience,
        date: date,
        adults: adults,
        minors: minors,
        minorsSupervisionConfirmed: minorsSupervisionConfirmed,
        minimumAgeConfirmed: minimumAgeConfirmed,
      );
      await getAll();
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final bookings = await getAll();
    bookings.add({
      'id': _uuid.v4(),
      'experience_id': experience['id'],
      'experience_title': experience['title'],
      'provider_id': experience['provider_id'],
      'provider_name': experience['provider'],
      'location': experience['location'],
      'price': experience['price'],
      'image': (experience['images'] as List).first,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'guests': adults + minors,
      'adults': adults,
      'minors': minors,
      'age_policy': experience['age_policy'] ?? 'all_ages',
      'minors_supervision_confirmed': minorsSupervisionConfirmed,
      'minimum_age_confirmed': minimumAgeConfirmed,
      'status': 'requested',
      'payment_status': 'not_applicable',
      'created_at': DateTime.now().toIso8601String(),
    });
    await preferences.setString(_storageKey, jsonEncode(bookings));
    changes.value = List.unmodifiable(bookings);
  }
}
