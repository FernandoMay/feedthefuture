import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String donationId;
  final String raterId;
  final String ratedUserId;
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final String? raterName;
  final String? raterPhotoUrl;

  Rating({
    required this.id,
    required this.donationId,
    required this.raterId,
    required this.ratedUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.raterName,
    this.raterPhotoUrl,
  });

  factory Rating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      donationId: data['donationId'] ?? '',
      raterId: data['raterId'] ?? '',
      ratedUserId: data['ratedUserId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      raterName: data['raterName'],
      raterPhotoUrl: data['raterPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donationId': donationId,
      'raterId': raterId,
      'ratedUserId': ratedUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'raterName': raterName,
      'raterPhotoUrl': raterPhotoUrl,
    };
  }

  Rating copyWith({
    String? id,
    String? donationId,
    String? raterId,
    String? ratedUserId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? raterName,
    String? raterPhotoUrl,
  }) {
    return Rating(
      id: id ?? this.id,
      donationId: donationId ?? this.donationId,
      raterId: raterId ?? this.raterId,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      raterName: raterName ?? this.raterName,
      raterPhotoUrl: raterPhotoUrl ?? this.raterPhotoUrl,
    );
  }
}

class UserRatingStats {
  final String userId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // 1-5 stars count

  UserRatingStats({
    required this.userId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory UserRatingStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRatingStats(
      userId: doc.id,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {
        1: 0, 2: 0, 3: 0, 4: 0, 5: 0
      }),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': ratingDistribution,
    };
  }
}
