import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Stream<ProfileModel?> watchCurrentProfile() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((rows) {
          if (rows.isEmpty) {
            return ProfileModel(
              id: user.id,
              email: user.email ?? '',
              fullName: user.userMetadata?['full_name'] as String?,
              role: 'Agent',
            );
          }
          return ProfileModel.fromJson(rows.first);
        });
  }

  Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select('id, email, full_name, avatar_url, role, updated_at')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        return ProfileModel(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String?,
          role: 'Agent',
        );
      }
      return ProfileModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final currentProfileStreamProvider = StreamProvider.autoDispose<ProfileModel?>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchCurrentProfile();
});

final currentProfileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getCurrentProfile();
});
