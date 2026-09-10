import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/deal_model.dart';
import '../../../data/repositories/deals_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  String _selectedStage = 'all';

  void _showStagePicker(DealModel deal) {
    final stages = [
      {'key': 'lead', 'label': 'Lead / Discovery'},
      {'key': 'qualified', 'label': 'Meeting Scheduled'},
      {'key': 'proposal', 'label': 'Proposal Sent'},
      {'key': 'negotiation', 'label': 'Negotiation'},
      {'key': 'won', 'label': 'Closed Won'},
      {'key': 'lost', 'label': 'Closed Lost'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'Move Deal Stage',
                    style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ...stages.map((st) {
                  final key = st['key']!;
                  final label = st['label']!;
                  final isCurrent = deal.stage == key;
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isCurrent ? ctx.colorScheme.primary : null,
                    ),
                    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: StatusBadge(status: key),
                    onTap: () async {
                      ctx.pop();
                      try {
                        await ref.read(dealsRepositoryProvider).updateDealStage(deal.id, key);
                        if (mounted) context.showSnackBar('Deal moved to $label');
                      } catch (e) {
                        if (mounted) context.showSnackBar(e.toString(), isError: true);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals & Pipeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () => context.push(AppRoutes.dealCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildStageFilter('all', 'All Stages'),
                _buildStageFilter('lead', 'Lead'),
                _buildStageFilter('qualified', 'Meeting'),
                _buildStageFilter('proposal', 'Proposal'),
                _buildStageFilter('negotiation', 'Negotiation'),
                _buildStageFilter('won', 'Won'),
                _buildStageFilter('lost', 'Lost'),
              ],
            ),
          ),

          // Deals List
          Expanded(
            child: dealsAsync.when(
              data: (allDeals) {
                var filtered = allDeals;
                if (_selectedStage != 'all') {
                  filtered = filtered
                      .where((d) => d.stage.toLowerCase() == _selectedStage.toLowerCase())
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    title: 'No Deals in Pipeline',
                    description: 'Track pipeline revenue and stages by creating deals.',
                    icon: Icons.monetization_on_outlined,
                    actionLabel: 'New Deal',
                    onAction: () => context.push(AppRoutes.dealCreate),
                  );
                }

                // Calculate total filtered value
                final totalValue = filtered.fold<double>(0, (sum, d) => sum + d.value);

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(dealsStreamProvider),
                  child: Column(
                    children: [
                      // Header summary banner
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filtered.length} Deals Active',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total: ${Formatters.currency(totalValue)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final deal = filtered[index];
                            return _buildDealCard(context, deal);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const LoadingIndicator(message: 'Loading pipeline...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(dealsStreamProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.dealCreate),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildStageFilter(String key, String label) {
    final isSelected = _selectedStage == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primarySubtle,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: isSelected ? const Color(0xFFBFDBFE) : AppColors.lightBorder,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedStage = key);
          }
        },
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, DealModel deal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: InkWell(
        onTap: () => context.push('/deals/${deal.id}/edit'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      deal.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showStagePicker(deal),
                    child: StatusBadge(status: deal.stage),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(deal.value),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                  if (deal.expectedCloseDate != null)
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 14, color: AppColors.lightTextMuted),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.date(deal.expectedCloseDate),
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
                        ),
                      ],
                    ),
                ],
              ),
              if (deal.notes != null && deal.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  deal.notes!,
                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
