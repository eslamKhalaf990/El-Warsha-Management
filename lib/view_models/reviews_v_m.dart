import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/models/review.dart';
import 'package:warsha_app/services/reviews_service.dart';

/// Reviews screen: moderate what customers wrote in the store (approve,
/// publish, feature, reply, delete).
class ReviewsVM extends ChangeNotifier with AsyncViewModel {
  ReviewsVM(this._service);

  final ReviewsService _service;

  static const replyMaxLength = 2000;

  List<Review> _all = [];
  String _query = '';
  ReviewStatus? _status = ReviewStatus.pending;
  int? _rating;

  List<Review> get allReviews => List.unmodifiable(_all);
  String get query => _query;
  ReviewStatus? get statusFilter => _status;
  int? get ratingFilter => _rating;

  /// Reviews matching the filters, newest first.
  List<Review> get reviews {
    final q = _query.trim().toLowerCase();
    bool has(String? s) => s != null && s.toLowerCase().contains(q);
    return _all
        .where((r) => _status == null || r.status == _status)
        .where((r) => _rating == null || r.rating == _rating)
        .where((r) => q.isEmpty || has(r.customerName) || has(r.comment) || has(r.productName) || has(r.subject))
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  Map<ReviewStatus, int> get statusCounts {
    final counts = <ReviewStatus, int>{};
    for (final r in _all) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Average stars of approved reviews, or null with none.
  double? get averageRating {
    final rated = _all.where((r) => r.status == ReviewStatus.approved && r.rating > 0).toList();
    if (rated.isEmpty) return null;
    return rated.fold<int>(0, (s, r) => s + r.rating) / rated.length;
  }

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void setQuery(String q) {
    _query = q;
    notify();
  }

  void setStatusFilter(ReviewStatus? s) {
    _status = s;
    notify();
  }

  void setRatingFilter(int? r) {
    _rating = r;
    notify();
  }

  /// Approving also publishes; rejecting hides and un-views.
  Future<bool> setStatus(Review r, ReviewStatus status) => _replace(r, () => _service.moderate(
        r.id,
        status: status,
        isPublic: status == ReviewStatus.approved ? true : (status == ReviewStatus.rejected ? false : null),
        isFeatured: status == ReviewStatus.rejected ? false : null,
      ));

  Future<bool> setPublic(Review r, bool value) =>
      _replace(r, () => _service.moderate(r.id, isPublic: value, isFeatured: value ? null : false));

  /// Featuring needs the review to be public too.
  Future<bool> setFeatured(Review r, bool value) =>
      _replace(r, () => _service.moderate(r.id, isFeatured: value, isPublic: value ? true : null));

  Future<bool> reply(Review r, String text) {
    final t = text.trim();
    if (t.isEmpty) return Future.value(fail(ApiException.validation({'reply': 'Write a reply first.'})));
    if (t.length > replyMaxLength) {
      return Future.value(fail(ApiException.validation({'reply': 'A reply can be at most $replyMaxLength characters.'})));
    }
    return _replace(r, () => _service.reply(r.id, t));
  }

  Future<bool> delete(Review r) => run(() async {
        await _service.delete(r.id);
        _all = _all.where((x) => x.id != r.id).toList();
      });

  Future<bool> _replace(Review r, Future<Review> Function() call) => run(() async {
        final updated = await call();
        _all = [for (final x in _all) x.id == r.id ? updated : x];
      });
}
