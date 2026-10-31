import 'json_read.dart';

/// Moderation state of a review (backend: CustomerFeedback.status).
enum ReviewStatus {
  pending('PENDING', 'Waiting'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  resolved('RESOLVED', 'Resolved');

  const ReviewStatus(this.api, this.label);

  final String api;
  final String label;

  static ReviewStatus parse(Object? v) =>
      values.firstWhere((s) => s.api == '$v'.toUpperCase(), orElse: () => ReviewStatus.pending);
}

/// What the review is about, as the store sends it.
const reviewTypes = {
  'PRODUCT': 'Product',
  'ORDER': 'Order',
  'SERVICE': 'Service',
  'GENERAL': 'General',
  'SUGGESTION': 'Suggestion',
  'COMPLAINT': 'Complaint',
};

/// A customer review or message from the store (backend: FeedbackResponse).
class Review {
  const Review({
    required this.id,
    required this.customerName,
    required this.type,
    required this.comment,
    required this.rating,
    required this.status,
    this.customerPhone,
    this.customerEmail,
    this.productId,
    this.productName,
    this.orderId,
    this.subject,
    this.isPublic = false,
    this.isFeatured = false,
    this.adminReply,
    this.repliedBy,
    this.repliedAt,
    this.createdAt,
  });

  final int id;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int? productId;
  final String? productName;
  final int? orderId;
  final String type;
  final String? subject;
  final String comment;
  final int rating;
  final ReviewStatus status;

  /// Shown on the store (reviews / testimonials).
  final bool isPublic;

  /// Highlighted on the store's home page.
  final bool isFeatured;
  final String? adminReply;
  final String? repliedBy;
  final DateTime? repliedAt;
  final DateTime? createdAt;

  String get typeLabel => reviewTypes[type.toUpperCase()] ?? type;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: readInt(json['id']) ?? 0,
        customerName: readString(json['customerName'], 'Guest'),
        customerPhone: readStringOrNull(json['customerPhone']),
        customerEmail: readStringOrNull(json['customerEmail']),
        productId: readInt(json['productId']),
        productName: readStringOrNull(json['productName']),
        orderId: readInt(json['orderId']),
        type: readString(json['feedbackType'], 'GENERAL'),
        subject: readStringOrNull(json['subject']),
        comment: readString(json['comment']),
        rating: readInt(json['rating']) ?? 0,
        status: ReviewStatus.parse(json['status']),
        isPublic: json['isPublic'] == true,
        isFeatured: json['isFeatured'] == true,
        adminReply: readStringOrNull(json['adminReply']),
        repliedBy: readStringOrNull(json['repliedBy']),
        repliedAt: readDate(json['repliedAt']),
        createdAt: readDate(json['createdAt']),
      );
}
