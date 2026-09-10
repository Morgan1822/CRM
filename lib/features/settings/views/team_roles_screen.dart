import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/user_permissions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';

class TeamRolesScreen extends ConsumerWidget {
  const TeamRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final theme = context.theme;

    // RBAC Security Guard: Non-admins cannot access team roles management
    if (!userRole.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Admin Access Required',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Managing team roles and permissions is restricted to Administrators only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final teamAsync = ref.watch(teamProfilesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team & Role Management'),
      ),
      body: teamAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No team members found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final member = members[index];
              final role = member.role ?? 'Agent';
              final isCurrentUser = member.id == ref.watch(currentProfileStreamProvider).value?.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(Formatters.initials(member.fullName ?? member.email)),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.fullName ?? 'Team Member',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    member.email,
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role, theme).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getRoleColor(role, theme).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role, theme),
                      ),
                    ),
                  ),
                  onTap: () => _showChangeRoleDialog(context, ref, member),
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error loading team: $e')),
      ),
    );
  }

  Color _getRoleColor(String role, ThemeData theme) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.indigo;
      case 'agent':
      default:
        return theme.colorScheme.primary;
    }
  }

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref, ProfileModel member) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Role for ${member.fullName ?? member.email}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the new permission level for this team member:',
                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 16),
                _buildRoleOption(ctx, ref, member, 'Admin', 'Full CRUD and Team Role Management', Colors.red),
                _buildRoleOption(ctx, ref, member, 'Manager', 'Full CRM Operations (no team management)', Colors.indigo),
                _buildRoleOption(ctx, ref, member, 'Agent', 'Standard View, Create & Edit (no delete)', theme.colorScheme.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(
    BuildContext ctx,
    WidgetRef ref,
    ProfileModel member,
    String roleName,
    String description,
    Color roleColor,
  ) {
    final isSelected = (member.role ?? 'Agent').toLowerCase() == roleName.toLowerCase();
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? roleColor : Colors.grey,
      ),
      title: Text(
        roleName,
        style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: () async {
        Navigator.pop(ctx);
        try {
          await ref.read(profileRepositoryProvider).updateUserRole(member.id, roleName);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Updated ${member.fullName ?? member.email} to $roleName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Failed to update role: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}
