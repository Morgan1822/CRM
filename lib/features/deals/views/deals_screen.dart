import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
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
    final stages = ['lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost'];

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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Move Deal Stage',
                    style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ...stages.map((stage) {
                  final isCurrent = deal.stage == stage;
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isCurrent ? ctx.colorScheme.primary : null,
                    ),
                    title: Text(stage.toUpperCase()),
                    trailing: StatusBadge(status: stage),
                    onTap: () async {
                      ctx.pop();
                      try {
                        await ref.read(dealsRepositoryProvider).updateDealStage(deal.id, stage);
                        if (mounted) context.showSnackBar('Deal stage updated');
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
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline'),
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
              children: ['all', 'lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost']
                  .map((stage) {
                final isSelected = _selectedStage == stage;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(stage.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStage = selected ? stage : 'all';
                      });
                    },
                  ),
                );
              }).toList(),
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
                    title: 'No Deals Found',
                    description: 'Track pipeline revenue by creating your first deal.',
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filtered.length} Deals',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Total: ${Formatters.currency(totalValue)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        onPressed: () => context.push(AppRoutes.dealCreate),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, DealModel deal) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/deals/${deal.id}/edit'),
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(deal.value),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  if (deal.expectedCloseDate != null)
                    Text(
                      'Close: ${Formatters.date(deal.expectedCloseDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              if (deal.notes != null && deal.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  deal.notes!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
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
