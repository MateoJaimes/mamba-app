import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env.dart';

class CurrencyService extends ChangeNotifier {
  CurrencyService._();
  static final instance = CurrencyService._();
  String code = 'COP';
  double rate = 1;
  String? updatedAt;
  bool stale = false;
  Future<void> load() async {
    code = "COP";
    rate = 1;
    updatedAt = null;
    stale = false;
    notifyListeners();
    if (!AppEnvironment.hasSupabaseConfig) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      code = 'COP';
      rate = 1;
      notifyListeners();
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('preferred_currency')
          .eq('id', user.id)
          .single();
      await select(
        profile['preferred_currency'] as String? ?? 'COP',
        persist: false,
      );
    } catch (_) {
      /* Keep COP if a fresh conversion cannot be obtained. */
    }
  }

  Future<void> select(String value, {bool persist = true}) async {
    final response =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ).get(
          '${AppEnvironment.supabaseUrl}/api/currency',
          queryParameters: {'code': value},
        );
    final data = Map<String, dynamic>.from(response.data as Map);
    final conversion = (data['rate'] as num).toDouble();
    if (conversion <= 0 || !conversion.isFinite) {
      throw StateError('Tasa inválida');
    }
    if (persist) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'preferred_currency': value})
            .eq('id', user.id);
      }
    }
    code = value;
    rate = conversion;
    updatedAt = data['updatedAt'] as String?;
    stale = data['stale'] == true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mapo.currency', value);
    notifyListeners();
  }

  static num amount(Map<String, dynamic> plan) =>
      plan['price_amount'] as num? ??
      num.tryParse('${plan['price'] ?? 0}'.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;
  String format(num cop, {bool approximate = true}) {
    final decimals = ['COP', 'JPY', 'CLP'].contains(code) ? 0 : 2;
    final formatted = NumberFormat.currency(
      locale: 'es_CO',
      name: code,
      symbol: code,
      decimalDigits: decimals,
    ).format(cop * rate);
    return code != 'COP' && approximate ? '≈ $formatted' : formatted;
  }
}
