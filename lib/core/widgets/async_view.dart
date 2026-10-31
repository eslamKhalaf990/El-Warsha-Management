import 'package:flutter/material.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/widgets/state_views.dart';

/// Picks what a screen driven by an [AsyncViewModel] shows: a skeleton until
/// the first load, an error with retry if it failed, [empty] when there is
/// nothing, otherwise [builder].
class AsyncView extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.vm,
    required this.isEmpty,
    required this.empty,
    required this.builder,
    required this.onRetry,
    this.loading,
  });

  final AsyncViewModel vm;
  final bool isEmpty;
  final Widget empty;
  final WidgetBuilder builder;
  final VoidCallback onRetry;

  /// Defaults to a [SkeletonList].
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    if (vm.loadFailed) return ErrorView(message: vm.errorMessage!, onRetry: onRetry);
    if (!vm.hasLoaded) return loading ?? const SkeletonList();
    if (isEmpty) return empty;
    return builder(context);
  }
}
