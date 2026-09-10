import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final themeMode = ref.watch(themeProvider);
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Card
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile.role ?? 'Agent',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LoadingIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

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
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Theme'),
                  subtitle: const Text('Match device appearance'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications & Shortcuts
          Text(
            'Preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('View your alerts and updates'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Action
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
}
