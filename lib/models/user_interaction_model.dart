// lib/models/user_interaction_model.dart

class UserInteraction {
  final String destinationId;
  final bool liked; // true = accepté, false = rejeté
  final DateTime timestamp;

  UserInteraction({
    required this.destinationId,
    required this.liked,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'destinationId': destinationId,
      'liked': liked,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserInteraction.fromJson(Map<String, dynamic> json) {
    return UserInteraction(
      destinationId: json['destinationId'],
      liked: json['liked'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
