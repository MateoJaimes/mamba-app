import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env.dart';
import 'account_service.dart';

/// Navigation follows trusted server roles, never registration intent.
class AccountSession extends ChangeNotifier {
  AccountSession._();
  static final instance = AccountSession._();
  AccountSnapshot? account;
  Object? error;
  bool loading = false;
  String? _userId;
  int _generation = 0;
  bool get isHost => account?.canHost == true;
  Future<void> refresh() async {
    if (!AppEnvironment.hasSupabaseConfig) return;
    final user = Supabase.instance.client.auth.currentUser?.id;
    final generation = ++_generation;
    if (user != _userId) {
      account = null;
      _userId = user;
    }
    error = null;
    loading = user != null;
    notifyListeners();
    if (user == null) return;
    try {
      final result = await AccountService.load();
      if (generation == _generation) account = result;
    } catch (e) {
      if (generation == _generation) error = e;
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }
}
