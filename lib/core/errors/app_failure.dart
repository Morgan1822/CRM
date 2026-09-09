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
  String toString() => 'AppFailure(code: $code, message: $message)';

  factory AppFailure.fromSupabase(dynamic error, [StackTrace? stackTrace]) {
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
