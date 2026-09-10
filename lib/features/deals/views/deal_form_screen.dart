import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/deal_model.dart';
import '../../../data/repositories/deals_repository.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';

class DealFormScreen extends ConsumerStatefulWidget {
  final String? dealId;

  const DealFormScreen({super.key, this.dealId});

  @override
  ConsumerState<DealFormScreen> createState() => _DealFormScreenState();
}

class _DealFormScreenState extends ConsumerState<DealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String _stage = 'lead';
  DateTime? _expectedCloseDate;
  String? _selectedContactId;
  bool _isLoading = false;
  bool _isFetching = false;
  DealModel? _existingDeal;

  @override
  void initState() {
    super.initState();
    if (widget.dealId != null) {
      _loadExistingDeal();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDeal() async {
    setState(() => _isFetching = true);
    try {
      final deal = await ref.read(dealsRepositoryProvider).getDealById(widget.dealId!);
      _existingDeal = deal;
      _titleController.text = deal.title;
      _valueController.text = deal.value.toStringAsFixed(0);
      _stage = deal.stage;
      _notesController.text = deal.notes ?? '';
      _expectedCloseDate = deal.expectedCloseDate;
      _selectedContactId = deal.contactId;
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedCloseDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expectedCloseDate = picked);
    }
  }

  Future<void> _saveDeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(dealsRepositoryProvider);
      final value = double.tryParse(_valueController.text.replaceAll(',', '')) ?? 0.0;

      if (_existingDeal != null) {
        final updated = _existingDeal!.copyWith(
          title: _titleController.text.trim(),
          value: value,
          stage: _stage,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          expectedCloseDate: _expectedCloseDate,
          contactId: _selectedContactId,
        );
        await repo.updateDeal(updated);
        if (mounted) {
          context.showSnackBar('Deal updated');
          context.pop();
        }
      } else {
        final newDeal = DealModel(
          id: '',
          title: _titleController.text.trim(),
          value: value,
          stage: _stage,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          expectedCloseDate: _expectedCloseDate,
          contactId: _selectedContactId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createDeal(newDeal);
        if (mounted) {
          context.showSnackBar('Deal created successfully');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadingIndicator(),
      );
    }

    final isEditing = widget.dealId != null;
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Deal' : 'New Deal'),
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Deal'),
                        content: const Text('Are you sure you want to delete this deal?'),
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
                      await ref.read(dealsRepositoryProvider).deleteDeal(widget.dealId!);
                      if (context.mounted) {
                        context.showSnackBar('Deal deleted');
                        context.pop();
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Deal Title *',
                hint: 'e.g. Enterprise License Expansion',
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _valueController,
                label: 'Deal Value (₹) *',
                hint: '50000',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.number,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _stage,
                decoration: const InputDecoration(labelText: 'Pipeline Stage'),
                items: const [
                  DropdownMenuItem(value: 'lead', child: Text('Lead')),
                  DropdownMenuItem(value: 'qualified', child: Text('Qualified')),
                  DropdownMenuItem(value: 'proposal', child: Text('Proposal Sent')),
                  DropdownMenuItem(value: 'negotiation', child: Text('Negotiation')),
                  DropdownMenuItem(value: 'won', child: Text('Closed Won')),
                  DropdownMenuItem(value: 'lost', child: Text('Closed Lost')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _stage = val);
                },
              ),
              const SizedBox(height: 14),
              // Expected Close Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expected Close Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                  child: Text(
                    _expectedCloseDate != null
                        ? Formatters.date(_expectedCloseDate)
                        : 'Select date',
                    style: TextStyle(
                      color: _expectedCloseDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Associated Contact Dropdown
              contactsAsync.when(
                data: (contacts) {
                  return DropdownButtonFormField<String?>(
                    value: _selectedContactId,
                    decoration: const InputDecoration(
                      labelText: 'Associated Contact (Optional)',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Contact Linked'),
                      ),
                      ...contacts.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text('${c.fullName} (${c.company ?? 'No Company'})'),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedContactId = val),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _notesController,
                label: 'Deal Notes',
                maxLines: 3,
                hint: 'Add closing terms, requirements, or next steps...',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: isEditing ? 'Save Changes' : 'Create Deal',
                isLoading: _isLoading,
                onPressed: _saveDeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
