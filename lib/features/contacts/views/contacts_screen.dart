import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final dialable = Formatters.dialablePhone(phone);
    final uri = Uri.parse('tel:$dialable');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => context.push(AppRoutes.contactCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search contacts by name, email, company...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: ['all', 'lead', 'qualified', 'customer', 'inactive'].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(status.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : 'all';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Contacts List
          Expanded(
            child: contactsAsync.when(
              data: (allContacts) {
                final q = _searchController.text.toLowerCase().trim();
                var filtered = allContacts;
                if (q.isNotEmpty) {
                  filtered = filtered.where((c) {
                    return c.fullName.toLowerCase().contains(q) ||
                        (c.email?.toLowerCase().contains(q) ?? false) ||
                        (c.company?.toLowerCase().contains(q) ?? false);
                  }).toList();
                }
                if (_selectedStatus != 'all') {
                  filtered = filtered
                      .where((c) => c.status.toLowerCase() == _selectedStatus.toLowerCase())
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    title: 'No Contacts Found',
                    description: q.isNotEmpty
                        ? 'Try modifying your search or filter'
                        : 'Start by creating your first contact or lead.',
                    icon: Icons.person_search_outlined,
                    actionLabel: 'Add Contact',
                    onAction: () => context.push(AppRoutes.contactCreate),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(contactsStreamProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      return _buildContactCard(context, contact);
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(message: 'Loading contacts...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(contactsStreamProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.contactCreate),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ContactModel contact) {
    final theme = context.theme;

    return Card(
      child: ListTile(
        onTap: () => context.push('/contacts/${contact.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: theme.colorScheme.primary,
          child: Text(
            Formatters.initials(contact.fullName),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            StatusBadge(status: contact.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.company != null && contact.company!.isNotEmpty)
                Text(
                  contact.company!,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (contact.email != null)
                Text(
                  contact.email!,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.phone != null && contact.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 20),
                onPressed: () => _makeCall(contact.phone!),
              ),
            if (contact.email != null && contact.email!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.email_outlined, size: 20),
                onPressed: () => _sendEmail(contact.email!),
              ),
          ],
        ),
      ),
    );
  }
}
