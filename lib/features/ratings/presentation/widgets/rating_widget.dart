import 'package:flutter/material.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';

class RatingWidget extends StatefulWidget {
  final int initialRating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;
  final bool showRating;
  final int totalRatings;

  const RatingWidget({
    super.key,
    this.initialRating = 0,
    this.size = 24.0,
    this.interactive = true,
    this.onRatingChanged,
    this.showRating = true,
    this.totalRatings = 0,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: widget.interactive
                  ? () {
                      setState(() {
                        _currentRating = index + 1;
                      });
                      widget.onRatingChanged?.call(_currentRating);
                    }
                  : null,
              child: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                color: index < _currentRating ? Colors.amber : Colors.grey[300],
                size: widget.size,
              ),
            );
          }),
        ),
        
        // Rating text
        if (widget.showRating) ...[
          const SizedBox(width: 8),
          Text(
            '${_currentRating.toStringAsFixed(1)}${widget.totalRatings > 0 ? ' ($widget.totalRatings)' : ''}',
            style: TextStyle(
              fontSize: widget.size * 0.6,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final int rating;
  final String comment;
  final DateTime date;

  const ReviewCard({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: userPhotoUrl != null 
                      ? NetworkImage(userPhotoUrl!) 
                      : null,
                  child: userPhotoUrl == null 
                      ? const Icon(Icons.person, size: 20, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingWidget(
                            initialRating: rating,
                            size: 16,
                            interactive: false,
                            showRating: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Comment
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution;

  const RatingSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.greenDeep, AppTheme.greenMid],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Average rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingWidget(
                    initialRating: averageRating.round(),
                    size: 20,
                    interactive: false,
                    showRating: false,
                  ),
                  Text(
                    '$totalRatings calificaciones',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Rating distribution
          ...List.generate(5, (index) {
            final starCount = 5 - index;
            final count = ratingDistribution[starCount] ?? 0;
            final percentage = totalRatings > 0 ? count / totalRatings : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    '$starCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.white, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
