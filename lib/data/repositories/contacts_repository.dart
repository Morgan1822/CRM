import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../models/contact_model.dart';
import '../services/supabase_service.dart';

class ContactsRepository {
  final SupabaseClient _client;

  ContactsRepository(this._client);

  Stream<List<ContactModel>> watchContacts({String? searchQuery, String? statusFilter}) {
    // Realtime stream of contacts table
    return _client
        .from('contacts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          var items = rows.map((json) => ContactModel.fromJson(json)).toList();
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.toLowerCase().trim();
            items = items.where((c) {
              return c.fullName.toLowerCase().contains(q) ||
                  (c.email?.toLowerCase().contains(q) ?? false) ||
                  (c.company?.toLowerCase().contains(q) ?? false);
            }).toList();
          }
          if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
            items = items.where((c) => c.status.toLowerCase() == statusFilter.toLowerCase()).toList();
          }
          return items;
        });
  }

  Future<List<ContactModel>> getContacts() async {
    try {
      final data = await _client
          .from('contacts')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((json) => ContactModel.fromJson(json)).toList();
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<ContactModel> getContactById(String id) async {
    try {
      final data = await _client
          .from('contacts')
          .select()
          .eq('id', id)
          .single();
      return ContactModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<ContactModel> createContact(ContactModel contact) async {
    try {
      final data = await _client
          .from('contacts')
          .insert(contact.toJson(includeId: false))
          .select()
          .single();
      return ContactModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<ContactModel> updateContact(ContactModel contact) async {
    try {
      final data = await _client
          .from('contacts')
          .update(contact.toJson(includeId: false))
          .eq('id', contact.id)
          .select()
          .single();
      return ContactModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await _client.from('contacts').delete().eq('id', id);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepository(ref.watch(supabaseClientProvider));
});

final contactsStreamProvider = StreamProvider.autoDispose<List<ContactModel>>((ref) {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.watchContacts();
});
