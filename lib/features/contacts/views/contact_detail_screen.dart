import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class ContactDetailScreen extends ConsumerWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _deleteContact(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(contactsRepositoryProvider).deleteContact(contactId);
        if (context.mounted) {
          context.showSnackBar('Contact deleted');
          context.pop();
        }
      } catch (e) {
        if (context.mounted) context.showSnackBar(e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;

    return FutureBuilder<ContactModel>(
      future: ref.read(contactsRepositoryProvider).getContactById(contactId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const LoadingIndicator(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: snapshot.error?.toString() ?? 'Contact not found',
              onRetry: () => (context as Element).markNeedsBuild(),
            ),
          );
        }

        final contact = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Contact Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/contacts/$contactId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _deleteContact(context, ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    Formatters.initials(contact.fullName),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  contact.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (contact.jobTitle != null || contact.company != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [contact.jobTitle, contact.company].where((s) => s != null && s.isNotEmpty).join(' at '),
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
                const SizedBox(height: 8),
                StatusBadge(status: contact.status),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      enabled: contact.phone != null && contact.phone!.isNotEmpty,
                      onTap: () => _makeCall(contact.phone!),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.message_rounded,
                      label: 'Text',
                      enabled: contact.phone != null && contact.phone!.isNotEmpty,
                      onTap: () => _sendSms(contact.phone!),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.email_rounded,
                      label: 'Email',
                      enabled: contact.email != null && contact.email!.isNotEmpty,
                      onTap: () => _sendEmail(contact.email!),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(context, 'Email', contact.email ?? 'Not provided', Icons.email_outlined),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, 'Phone', contact.phone ?? 'Not provided', Icons.phone_outlined),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, 'Company', contact.company ?? 'Not provided', Icons.business_outlined),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, 'Created', Formatters.date(contact.createdAt), Icons.calendar_today_outlined),
                        if (contact.notes != null && contact.notes!.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            'Notes',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            contact.notes!,
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = context.theme;
    return Column(
      children: [
        IconButton.filledTonal(
          icon: Icon(icon),
          onPressed: enabled ? onTap : null,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: enabled ? theme.textTheme.bodyMedium?.color : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
