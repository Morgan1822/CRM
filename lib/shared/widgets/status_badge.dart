import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../extensions/string_extensions.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? customColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.customColor,
  });

  Color _resolveColor() {
    if (customColor != null) return customColor!;
    final normalized = status.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    switch (normalized) {
      case 'lead':
        return AppColors.stageLead;
      case 'qualified':
        return AppColors.stageQualified;
      case 'proposal':
        return AppColors.stageProposal;
      case 'negotiation':
        return AppColors.stageNegotiation;
      case 'won':
      case 'closedwon':
      case 'active':
      case 'completed':
        return AppColors.stageWon;
      case 'lost':
      case 'closedlost':
      case 'inactive':
        return AppColors.stageLost;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        status.titleCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
