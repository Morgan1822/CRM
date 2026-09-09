import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'loading_indicator.dart';
import 'error_view.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (e, stack) => ErrorView(
        message: e.toString(),
        onRetry: onRetry,
      ),
      loading: () => loading ?? const LoadingIndicator(),
    );
  }
}
