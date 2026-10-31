import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/review.dart';

/// Store reviews and messages (backend: CustomerFeedbackController under
/// `/feedbacks`, admin endpoints). Every failure is an ApiException.
class ReviewsService {
  ReviewsService(this._api);

  final ApiClient _api;

  Future<List<Review>> list() async => readList(await _api.get('feedbacks')).map(Review.fromJson).toList();

  /// Changes any of [status], [isPublic], [isFeatured]; null leaves it as is.
  Future<Review> moderate(int id, {ReviewStatus? status, bool? isPublic, bool? isFeatured}) async =>
      Review.fromJson(readMap(await _api.put('feedbacks/$id/status', body: {
            if (status != null) 'status': status.api,
            if (isPublic != null) 'isPublic': isPublic,
            if (isFeatured != null) 'isFeatured': isFeatured,
          })) ??
          const {});

  Future<Review> reply(int id, String reply) async =>
      Review.fromJson(readMap(await _api.post('feedbacks/$id/reply', body: {'reply': reply.trim()})) ?? const {});

  Future<void> delete(int id) => _api.delete('feedbacks/$id');
}
