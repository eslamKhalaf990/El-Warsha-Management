import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/ui/feedback.dart';

/// The body of a list screen driven by an [AsyncViewModel]: a spinner until
/// the first load, a retry view if it failed, an empty or no-match message,
/// otherwise the list with pull-to-refresh.
class AsyncListBody<T> extends StatelessWidget {
  const AsyncListBody({
    super.key,
    required this.vm,
    required this.items,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyText,
    this.query = '',
  });

  final AsyncViewModel vm;
  final List<T> items;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;

  /// The current search text, for the "no match" message.
  final String query;

  @override
  Widget build(BuildContext context) {
    if (vm.loadFailed) {
      return LoadErrorView(message: vm.errorMessage!, onRetry: onRefresh);
    }
    if (!vm.hasLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 180.0),
          child: SpinKitChasingDots(color: Theme.of(context).colorScheme.tertiary, size: 30),
        ),
      );
    }
    if (items.isEmpty) {
      final q = query.trim();
      return Center(child: Text(q.isEmpty ? emptyText : 'Nothing matches "$q".'));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: items.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) => itemBuilder(context, items[index]),
      ),
    );
  }
}
