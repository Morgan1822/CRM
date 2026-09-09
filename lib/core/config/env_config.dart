import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration loaded from .env
class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback if .env is missing in tests or bundle
    }
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.placeholder_anon_key';

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static String get deepLinkHost => dotenv.env['DEEP_LINK_HOST'] ?? 'crm.app';

  static bool get isDev => appEnv == 'development';
}
