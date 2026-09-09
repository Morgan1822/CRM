import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../models/deal_model.dart';
import '../services/supabase_service.dart';

class DealsRepository {
  final SupabaseClient _client;

  DealsRepository(this._client);

  Stream<List<DealModel>> watchDeals({String? stageFilter}) {
    return _client
        .from('deals')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          var items = rows.map((json) => DealModel.fromJson(json)).toList();
          if (stageFilter != null && stageFilter != 'all') {
            items = items.where((d) => d.stage.toLowerCase() == stageFilter.toLowerCase()).toList();
          }
          return items;
        });
  }

  Future<List<DealModel>> getDeals() async {
    try {
      final data = await _client
          .from('deals')
          .select('*, contact:contacts(first_name, last_name)')
          .order('created_at', ascending: false);
      return (data as List).map((json) => DealModel.fromJson(json)).toList();
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<DealModel> getDealById(String id) async {
    try {
      final data = await _client
          .from('deals')
          .select('*, contact:contacts(first_name, last_name)')
          .eq('id', id)
          .single();
      return DealModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<DealModel> createDeal(DealModel deal) async {
    try {
      final data = await _client
          .from('deals')
          .insert(deal.toJson(includeId: false))
          .select()
          .single();
      return DealModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<DealModel> updateDeal(DealModel deal) async {
    try {
      final data = await _client
          .from('deals')
          .update(deal.toJson(includeId: false))
          .eq('id', deal.id)
          .select()
          .single();
      return DealModel.fromJson(data);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> updateDealStage(String dealId, String newStage) async {
    try {
      await _client
          .from('deals')
          .update({'stage': newStage, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', dealId);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }

  Future<void> deleteDeal(String id) async {
    try {
      await _client.from('deals').delete().eq('id', id);
    } catch (e, st) {
      throw AppFailure.fromSupabase(e, st);
    }
  }
}

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return DealsRepository(ref.watch(supabaseClientProvider));
});

final dealsStreamProvider = StreamProvider.autoDispose<List<DealModel>>((ref) {
  final repo = ref.watch(dealsRepositoryProvider);
  return repo.watchDeals();
});
