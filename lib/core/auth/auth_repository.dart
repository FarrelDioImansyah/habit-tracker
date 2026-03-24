import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_provider.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Daftar dengan email & password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return res;
  }

  // Login dengan email & password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res;
  }

  // Login dengan Google (OAuth)
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  // Logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password via email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
