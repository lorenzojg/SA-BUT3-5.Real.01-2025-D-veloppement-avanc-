// lib/models/user_interaction_model.dart

enum InteractionType {
  like,
  dislike,
  viewDetails,
  addToFavorites,
}

class UserInteraction {
  final String destinationId;
  final InteractionType type;
  final DateTime timestamp;
  final int durationMs; // Durée de l'interaction (ex: temps avant de swiper)

  UserInteraction({
    required this.destinationId,
    required this.type,
    required this.timestamp,
    this.durationMs = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'destinationId': destinationId,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'durationMs': durationMs,
    };
  }

  factory UserInteraction.fromJson(Map<String, dynamic> json) {
    return UserInteraction(
      destinationId: json['destinationId'],
      type: InteractionType.values.firstWhere((e) => e.toString() == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      durationMs: json['durationMs'] ?? 0,
    );
  }
}
