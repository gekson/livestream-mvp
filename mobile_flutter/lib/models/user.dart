class RoomUser {
  final String id;
  final String username;
  final bool isHost;
  final bool isMe;
  final bool isMuted;
  final bool isVideoEnabled;

  RoomUser({
    required this.id,
    required this.username,
    this.isHost = false,
    this.isMe = false,
    this.isMuted = false,
    this.isVideoEnabled = true,
  });

  factory RoomUser.fromJson(Map<String, dynamic> json, {bool isMe = false}) {
    return RoomUser(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Unknown',
      isHost: json['isHost'] ?? false,
      isMe: isMe,
      isMuted: json['isMuted'] ?? false,
      isVideoEnabled: json['isVideoEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'isHost': isHost,
      'isMuted': isMuted,
      'isVideoEnabled': isVideoEnabled,
    };
  }

  RoomUser copyWith({
    String? id,
    String? username,
    bool? isHost,
    bool? isMe,
    bool? isMuted,
    bool? isVideoEnabled,
  }) {
    return RoomUser(
      id: id ?? this.id,
      username: username ?? this.username,
      isHost: isHost ?? this.isHost,
      isMe: isMe ?? this.isMe,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
    );
  }
}