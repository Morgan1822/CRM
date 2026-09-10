import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/user_permissions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileStreamProvider);
    final userRole = ref.watch(userRoleProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile & Role Header Card
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              final roleName = profile.role ?? 'Agent';
              final roleColor = _getRoleBadgeColor(roleName, theme);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: Text(
                              Formatters.initials(profile.fullName ?? profile.email),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName ?? 'Team Member',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    roleName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      // Role Switching & Upgrade Controls
                      Row(
                        children: [
                          if (!userRole.isAdmin) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.security_rounded, size: 18),
                                label: const Text(
                                  'Promote to Admin',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: () => _updateCurrentUserRole(context, ref, 'Admin'),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                              label: const Text('Switch Role', style: TextStyle(fontSize: 13)),
                              onPressed: () => _showRoleSwitcherModal(context, ref, roleName),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LoadingIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Administration Section — EXCLUSIVELY VISIBLE TO ADMINS
          if (userRole.isAdmin) ...[
            Text(
              'Administration',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.red),
                title: const Text(
                  'Team & Role Management',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Assign Admin, Manager, or Agent permissions to team'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push(AppRoutes.teamRoles),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Appearance Section
          Text(
            'Appearance',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) {
                if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System Theme'),
                    subtitle: Text('Match device appearance'),
                    value: ThemeMode.system,
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: Text('Light Mode'),
                    value: ThemeMode.light,
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark Mode'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Preferences & Notifications
          Text(
            'Preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('View your alerts and updates'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => context.push(AppRoutes.notifications),
            ),
          ),
          const SizedBox(height: 20),

          // Account Sign Out
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out of your account?'),
                    actions: [
                      TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => ctx.pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'CRM v1.0.0',
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(String role, ThemeData theme) {
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

  void _showRoleSwitcherModal(BuildContext context, WidgetRef ref, String currentRole) {
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
                  'Switch Active Role',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch your account role to preview and test role permissions in real-time:',
                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 16),
                _buildRoleSwitcherItem(ctx, ref, currentRole, 'Admin', 'Full CRUD + Team Roles & Admin Settings', Colors.red),
                _buildRoleSwitcherItem(ctx, ref, currentRole, 'Manager', 'Full CRM Operations (No Team Admin)', Colors.indigo),
                _buildRoleSwitcherItem(ctx, ref, currentRole, 'Agent', 'Standard View, Create & Edit (No Delete)', theme.colorScheme.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleSwitcherItem(
    BuildContext ctx,
    WidgetRef ref,
    String currentRole,
    String targetRole,
    String description,
    Color color,
  ) {
    final isSelected = currentRole.toLowerCase() == targetRole.toLowerCase();
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? color : Colors.grey,
      ),
      title: Text(
        targetRole,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(ctx);
        if (!isSelected) {
          _updateCurrentUserRole(ctx, ref, targetRole);
        }
      },
    );
  }

  Future<void> _updateCurrentUserRole(BuildContext context, WidgetRef ref, String newRole) async {
    try {
      await ref.read(profileRepositoryProvider).updateRole(newRole);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account role updated to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
