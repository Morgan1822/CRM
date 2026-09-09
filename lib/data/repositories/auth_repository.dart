import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e, st) {
      throw AppFailure(message: e.message, code: e.statusCode, stackTrace: st);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName.trim()} : null,
      );
      return response;
    } on AuthException catch (e, st) {
      throw AppFailure(message: e.message, code: e.statusCode, stackTrace: st);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e, st) {
      throw AppFailure(message: e.message, code: e.statusCode, stackTrace: st);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
