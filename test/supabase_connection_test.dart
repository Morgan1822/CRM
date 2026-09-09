import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crm_mobile/core/config/env_config.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EnvConfig.init();
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
      ),
    );
  });

  test('Supabase client initializes with configured credentials', () {
    expect(Supabase.instance.client, isNotNull);
    expect(EnvConfig.supabaseUrl, contains('umzumlhcyjzzsarordrp'));
    expect(EnvConfig.supabaseAnonKey, isNotEmpty);
  });

  test('Supabase tables can be queried via client', () async {
    final client = Supabase.instance.client;
    
    // Test querying contacts table
    final contacts = await client.from('contacts').select().limit(5);
    expect(contacts, isA<List>());
    print('Contacts query success: found ${contacts.length} records');

    // Test querying deals table
    final deals = await client.from('deals').select().limit(5);
    expect(deals, isA<List>());
    print('Deals query success: found ${deals.length} records');

    // Test querying tasks table
    final tasks = await client.from('tasks').select().limit(5);
    expect(tasks, isA<List>());
    print('Tasks query success: found ${tasks.length} records');
  });

  test('Supabase Auth flow handles test authentication attempt gracefully', () async {
    final client = Supabase.instance.client;

    try {
      await client.auth.signInWithPassword(
        email: 'test_nonexistent_user_verification@company.com',
        password: 'Password123!',
      );
      fail('Expected AuthException for non-existent user');
    } on AuthException catch (e) {
      // Confirms auth server responded cleanly
      print('Auth endpoint verified: code=${e.statusCode}, message=${e.message}');
      expect(e.message, isNotEmpty);
    }
  });
}
