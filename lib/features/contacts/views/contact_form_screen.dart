import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  final String? contactId;

  const ContactFormScreen({super.key, this.contactId});

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'lead';
  bool _isLoading = false;
  bool _isFetching = false;
  ContactModel? _existingContact;

  @override
  void initState() {
    super.initState();
    if (widget.contactId != null) {
      _loadExistingContact();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingContact() async {
    setState(() => _isFetching = true);
    try {
      final contact = await ref.read(contactsRepositoryProvider).getContactById(widget.contactId!);
      _existingContact = contact;
      _firstNameController.text = contact.firstName;
      _lastNameController.text = contact.lastName;
      _emailController.text = contact.email ?? '';
      _phoneController.text = contact.phone ?? '';
      _companyController.text = contact.company ?? '';
      _jobTitleController.text = contact.jobTitle ?? '';
      _notesController.text = contact.notes ?? '';
      _status = contact.status;
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      if (_existingContact != null) {
        final updated = _existingContact!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          status: _status,
        );
        await repo.updateContact(updated);
        if (mounted) {
          context.showSnackBar('Contact updated successfully');
          context.pop();
        }
      } else {
        final newContact = ContactModel(
          id: '',
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          status: _status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createContact(newContact);
        if (mounted) {
          context.showSnackBar('Contact created successfully');
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

    final isEditing = widget.contactId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Contact' : 'New Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _firstNameController,
                      label: 'First Name *',
                      validator: Validators.required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _lastNameController,
                      label: 'Last Name *',
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.isNotEmpty ? Validators.email(v) : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _companyController,
                      label: 'Company',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _jobTitleController,
                      label: 'Job Title',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'lead', child: Text('Lead')),
                  DropdownMenuItem(value: 'qualified', child: Text('Qualified')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _notesController,
                label: 'Notes',
                maxLines: 3,
                hint: 'Add any relevant context or details...',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: isEditing ? 'Save Changes' : 'Create Contact',
                isLoading: _isLoading,
                onPressed: _saveContact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
