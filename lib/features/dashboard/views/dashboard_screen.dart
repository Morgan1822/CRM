import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/deal_model.dart';
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

    final profile = profileAsync.value;
    final userName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim().split(' ').first
        : 'Team Member';
    final roleName = profile?.role ?? 'Admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Text(
                Formatters.initials(profile?.fullName ?? profile?.email ?? 'CRM'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sales CRM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          roleName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Workspace',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contactsStreamProvider);
          ref.invalidate(dealsStreamProvider);
          ref.invalidate(tasksStreamProvider);
          ref.invalidate(currentProfileStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Welcome back, $userName ',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                            children: const [
                              TextSpan(
                                text: '👋',
                                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview of your sales pipeline, deals, contacts, and recent activities.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar matching Web App
              InkWell(
                onTap: () => context.go(AppRoutes.contacts),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: AppColors.lightTextMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search contacts, deals, tasks...',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KPI Stat Cards (2x2 Grid) matching Web
              dealsAsync.when(
                data: (deals) {
                  final openDeals = deals.where((d) => d.stage != 'lost').toList();
                  final pipelineTotal = openDeals.fold<double>(0, (sum, d) => sum + d.value);
                  final activeDealsCount = deals.where((d) => d.stage != 'won' && d.stage != 'lost').length;

                  return contactsAsync.when(
                    data: (contacts) {
                      return tasksAsync.when(
                        data: (tasks) {
                          final pendingTasksCount = tasks.where((t) => !t.isCompleted).length;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildWebKpiCard(
                                      context,
                                      title: 'Pipeline Value',
                                      value: Formatters.currency(pipelineTotal),
                                      subtitle: '${openDeals.length} active deals',
                                      icon: Icons.currency_rupee_rounded,
                                      iconColor: const Color(0xFF059669),
                                      iconBg: const Color(0xFFECFDF5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildWebKpiCard(
                                      context,
                                      title: 'Active Deals',
                                      value: '$activeDealsCount Deals',
                                      subtitle: activeDealsCount > 0 ? 'In active pipeline' : 'No active deals',
                                      icon: Icons.auto_graph_rounded,
                                      iconColor: const Color(0xFF2563EB),
                                      iconBg: const Color(0xFFEFF6FF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildWebKpiCard(
                                      context,
                                      title: 'Total Contacts',
                                      value: '${contacts.length} Contacts',
                                      subtitle: 'Active in CRM',
                                      icon: Icons.people_alt_outlined,
                                      iconColor: const Color(0xFF7C3AED),
                                      iconBg: const Color(0xFFF5F3FF),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildWebKpiCard(
                                      context,
                                      title: 'Pending Tasks',
                                      value: '$pendingTasksCount Tasks',
                                      subtitle: pendingTasksCount > 0 ? '$pendingTasksCount to complete' : 'All caught up!',
                                      icon: Icons.checklist_rounded,
                                      iconColor: const Color(0xFFD97706),
                                      iconBg: const Color(0xFFFFFBEB),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const LoadingIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                    loading: () => const LoadingIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Deal Pipeline Stages Section (matching Web)
              _buildPipelineStagesSection(context, dealsAsync),
              const SizedBox(height: 20),

              // Quick Actions Bar
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context,
                      label: 'New Contact',
                      icon: Icons.person_add_alt_1_rounded,
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

              // Recent Activity Section (matching Web)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latest contacts and updates',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.contacts),
                    child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              contactsAsync.when(
                data: (contacts) {
                  if (contacts.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No recent activity yet. Tap + to add your first contact.',
                          style: TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  final recents = contacts.take(4).toList();
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                      itemBuilder: (context, index) {
                        final contact = recents[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          onTap: () => context.push('/contacts/${contact.id}'),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primarySubtle,
                            foregroundColor: AppColors.primary,
                            child: Text(
                              Formatters.initials(contact.fullName),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          title: Text(
                            'Contact: ${contact.fullName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            contact.email?.isNotEmpty == true
                                ? contact.email!
                                : (contact.company ?? 'Contact added'),
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.date(contact.createdAt),
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(status: contact.status, isSmall: true),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Error loading activity: $e'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStagesSection(BuildContext context, AsyncValue<List<DealModel>> dealsAsync) {
    final theme = context.theme;

    final stagesConfig = [
      {'key': 'lead', 'label': 'Lead / Discovery', 'color': AppColors.stageLead},
      {'key': 'qualified', 'label': 'Meeting Scheduled', 'color': AppColors.stageQualified},
      {'key': 'proposal', 'label': 'Proposal Sent', 'color': AppColors.stageProposal},
      {'key': 'negotiation', 'label': 'Negotiation', 'color': AppColors.stageNegotiation},
      {'key': 'won', 'label': 'Closed Won', 'color': AppColors.stageWon},
      {'key': 'lost', 'label': 'Closed Lost', 'color': AppColors.stageLost},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deal Pipeline Stages',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live stage distribution across all open deals',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.deals),
              child: const Text('Pipeline', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        dealsAsync.when(
          data: (deals) {
            return SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stagesConfig.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final config = stagesConfig[index];
                  final stageKey = config['key'] as String;
                  final stageLabel = config['label'] as String;
                  final dotColor = config['color'] as Color;

                  final stageDeals = deals.where((d) => d.stage.toLowerCase() == stageKey).toList();
                  final totalValue = stageDeals.fold<double>(0, (sum, d) => sum + d.value);

                  return Container(
                    width: 145,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                stageLabel,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Formatters.currency(totalValue),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${stageDeals.length} deals',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const LoadingIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
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
