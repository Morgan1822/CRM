import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../extensions/string_extensions.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? customColor;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.customColor,
    this.isSmall = false,
  });

  (Color text, Color bg, Color border) _resolveColors() {
    if (customColor != null) {
      return (customColor!, customColor!.withValues(alpha: 0.12), customColor!.withValues(alpha: 0.25));
    }
    final normalized = status.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    switch (normalized) {
      case 'lead':
      case 'discovery':
        return (AppColors.stageLead, AppColors.stageLeadBg, const Color(0xFFCBD5E1));
      case 'qualified':
      case 'meeting':
      case 'meetingscheduled':
        return (AppColors.stageQualified, AppColors.stageQualifiedBg, const Color(0xFFBFDBFE));
      case 'proposal':
      case 'proposalsent':
        return (AppColors.stageProposal, AppColors.stageProposalBg, const Color(0xFFDDD6FE));
      case 'negotiation':
        return (AppColors.stageNegotiation, AppColors.stageNegotiationBg, const Color(0xFFFDE68A));
      case 'won':
      case 'closedwon':
      case 'customer':
      case 'completed':
        return (AppColors.stageWon, AppColors.stageWonBg, const Color(0xFFA7F3D0));
      case 'lost':
      case 'closedlost':
      case 'inactive':
        return (AppColors.stageLost, AppColors.stageLostBg, const Color(0xFFFECDD3));
      default:
        return (AppColors.primary, AppColors.primarySubtle, const Color(0xFFBFDBFE));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor, borderColor) = _resolveColors();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 9,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        status.titleCase(),
        style: TextStyle(
          color: textColor,
          fontSize: isSmall ? 10 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
