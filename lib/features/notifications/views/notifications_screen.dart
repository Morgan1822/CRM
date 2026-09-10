import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state_view.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const EmptyStateView(
        title: 'No New Notifications',
        description: 'You will receive updates when new leads, deal changes, or task reminders occur.',
        icon: Icons.notifications_none_rounded,
      ),
    );
  }
}
