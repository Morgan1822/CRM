import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';

enum UserRole {
  admin,
  manager,
  agent;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.agent;
    final normalized = role.trim().toLowerCase();
    if (normalized == 'admin') return UserRole.admin;
    if (normalized == 'manager') return UserRole.manager;
    return UserRole.agent;
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.agent:
        return 'Agent';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isManager => this == UserRole.manager;
  bool get isAgent => this == UserRole.agent;

  /// Admins and Managers have permission to permanently delete records
  bool get canDelete => this == UserRole.admin || this == UserRole.manager;

  /// Admins can manage system-wide settings, team members & roles
  bool get canManageTeam => this == UserRole.admin;
  bool get canManageSystemSettings => this == UserRole.admin;

  /// All roles can create & edit records
  bool get canEdit => true;
  bool get canCreate => true;
}

/// Reactive provider for current user permissions based on real-time profile data
final userRoleProvider = Provider<UserRole>((ref) {
  final profileAsync = ref.watch(currentProfileStreamProvider);
  return profileAsync.when(
    data: (profile) => UserRole.fromString(profile?.role),
    loading: () => UserRole.agent,
    error: (_, __) => UserRole.agent,
  );
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.isAdmin;
});

final canDeleteProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canDelete;
});
