import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_mobile/app.dart';
import 'package:crm_mobile/core/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('App smoke test initializes CrmApp widget tree', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EnvConfig.init();
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: CrmApp(),
      ),
    );

    // Initial pump and settle
    await tester.pump();
    expect(find.byType(CrmApp), findsOneWidget);
  });
}
