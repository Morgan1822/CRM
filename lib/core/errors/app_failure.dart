import 'package:supabase_flutter/supabase_flutter.dart';

/// Standard domain failure representation
class AppFailure implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppFailure({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  factory AppFailure.fromAuth(AuthException error, [StackTrace? stackTrace]) {
    final code = error.statusCode;
    final msg = error.message.toLowerCase();

    if (code == '429' || msg.contains('rate limit')) {
      return AppFailure(
        message: 'Email rate limit reached. Please wait a minute or turn off "Confirm email" in Supabase Auth settings for instant testing.',
        code: '429',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return AppFailure(
        message: 'This email is already registered. Please sign in instead.',
        code: 'USER_EXISTS',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return AppFailure(
        message: 'Invalid email or password. Please try again.',
        code: 'INVALID_CREDENTIALS',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppFailure(
      message: error.message,
      code: error.statusCode,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppFailure.fromSupabase(dynamic error, [StackTrace? stackTrace]) {
    if (error is AuthException) {
      return AppFailure.fromAuth(error, stackTrace);
    }
    if (error is AppFailure) {
      return error;
    }

    final msg = error?.toString() ?? 'An unexpected database error occurred';
    if (msg.contains('JWT') || msg.contains('expired')) {
      return AppFailure(
        message: 'Your session has expired. Please sign in again.',
        code: 'AUTH_EXPIRED',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (msg.contains('row-level security') || msg.contains('permission denied')) {
      return AppFailure(
        message: 'Permission denied: You do not have access to this resource.',
        code: 'RLS_DENIED',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    return AppFailure(
      message: msg,
      code: 'SUPABASE_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppFailure.network([dynamic error]) {
    return AppFailure(
      message: 'Network connection error. Please check your internet.',
      code: 'NETWORK_ERROR',
      originalError: error,
    );
  }
}
