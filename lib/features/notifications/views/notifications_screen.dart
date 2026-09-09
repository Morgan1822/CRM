import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/notification_service.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/empty_state_view.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(fcmTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          // Push Registration Banner
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Push Token Status',
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    token != null
                        ? 'Device registered with FCM & synced to Supabase `device_tokens` table.'
                        : 'Fetching device token / Waiting for permissions...',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  if (token != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Token: ${token.substring(0, 15)}...${token.substring(token.length - 10)}',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Expanded(
            child: EmptyStateView(
              title: 'No New Notifications',
              description: 'When new leads, deal updates, or task reminders occur, you will see them here.',
              icon: Icons.notifications_none_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
