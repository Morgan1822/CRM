import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../data/repositories/deals_repository.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsStreamProvider);
    final dealsAsync = ref.watch(dealsStreamProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final profileAsync = ref.watch(currentProfileStreamProvider);
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (profile) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile?.fullName != null && profile!.fullName!.trim().isNotEmpty
                    ? 'Hello, ${profile.fullName!.trim().split(' ').first}'
                    : 'Dashboard',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (profile?.role != null)
                Text(
                  profile!.role!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          loading: () => const Text('Dashboard'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contactsStreamProvider);
          ref.invalidate(dealsStreamProvider);
          ref.invalidate(tasksStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Pipeline Value',
                      value: dealsAsync.when(
                        data: (deals) {
                          final openDeals = deals.where((d) => d.stage != 'lost');
                          final total = openDeals.fold<double>(0, (sum, d) => sum + d.value);
                          return Formatters.currency(total);
                        },
                        loading: () => '...',
                        error: (_, __) => '₹0',
                      ),
                      icon: Icons.monetization_on_outlined,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Pending Tasks',
                      value: tasksAsync.when(
                        data: (tasks) => '${tasks.where((t) => !t.isCompleted).length}',
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.checklist_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Total Contacts',
                      value: contactsAsync.when(
                        data: (contacts) => '${contacts.length}',
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.people_alt_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Active Deals',
                      value: dealsAsync.when(
                        data: (deals) =>
                            '${deals.where((d) => d.stage != 'won' && d.stage != 'lost').length}',
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.trending_up_rounded,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Bar
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context,
                      label: 'New Contact',
                      icon: Icons.person_add_outlined,
                      onTap: () => context.push(AppRoutes.contactCreate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionButton(
                      context,
                      label: 'New Deal',
                      icon: Icons.post_add_rounded,
                      onTap: () => context.push(AppRoutes.dealCreate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionButton(
                      context,
                      label: 'New Task',
                      icon: Icons.add_task_rounded,
                      onTap: () => context.push(AppRoutes.taskCreate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's High Priority Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Tasks',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.tasks),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              tasksAsync.when(
                data: (tasks) {
                  final pending = tasks.where((t) => !t.isCompleted).take(3).toList();
                  if (pending.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No pending tasks. You are all caught up!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((task) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(tasksRepositoryProvider)
                                    .toggleTaskCompletion(task.id, val);
                              }
                            },
                          ),
                          title: Text(
                            task.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            task.dueDate != null
                                ? 'Due ${Formatters.date(task.dueDate)}'
                                : 'No due date',
                            style: TextStyle(
                              color: task.isOverdue ? Colors.red : null,
                            ),
                          ),
                          trailing: StatusBadge(status: task.type),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Error loading tasks: $e'),
              ),
              const SizedBox(height: 20),

              // Recent Contacts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Contacts',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.contacts),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              contactsAsync.when(
                data: (contacts) {
                  final recents = contacts.take(3).toList();
                  if (recents.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No contacts added yet. Tap + to add your first contact.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: recents.map((contact) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => context.push('/contacts/${contact.id}'),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                            foregroundColor: theme.colorScheme.primary,
                            child: Text(Formatters.initials(contact.fullName)),
                          ),
                          title: Text(
                            contact.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(contact.company ?? contact.email ?? 'No info'),
                          trailing: StatusBadge(status: contact.status),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Error loading contacts: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = context.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
