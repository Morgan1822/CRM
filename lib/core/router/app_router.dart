import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'route_names.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/contacts/views/contacts_screen.dart';
import '../../features/contacts/views/contact_detail_screen.dart';
import '../../features/contacts/views/contact_form_screen.dart';
import '../../features/deals/views/deals_screen.dart';
import '../../features/deals/views/deal_form_screen.dart';
import '../../features/tasks/views/tasks_screen.dart';
import '../../features/tasks/views/task_form_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../data/services/supabase_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (session == null && !isLoggingIn) {
        return AppRoutes.login;
      }
      if (session != null && isLoggingIn) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.contacts,
            builder: (context, state) => const ContactsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ContactFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final contactId = state.pathParameters['id']!;
                  return ContactDetailScreen(contactId: contactId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final contactId = state.pathParameters['id']!;
                      return ContactFormScreen(contactId: contactId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.deals,
            builder: (context, state) => const DealsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const DealFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final dealId = state.pathParameters['id']!;
                  return DealFormScreen(dealId: dealId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TasksScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const TaskFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.contacts)) return 1;
    if (location.startsWith(AppRoutes.deals)) return 2;
    if (location.startsWith(AppRoutes.tasks)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.contacts);
        break;
      case 2:
        context.go(AppRoutes.deals);
        break;
      case 3:
        context.go(AppRoutes.tasks);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        backgroundColor: theme.colorScheme.surface,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money_rounded),
            label: 'Deals',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
