import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthStateNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AsyncValue.data(null));

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? fullName}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendPasswordReset(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<void>>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});
