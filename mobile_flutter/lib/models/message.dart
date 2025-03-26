class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final String senderId;
  final DateTime timestamp;
  final bool isFromMe;  // Make sure this property exists

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.senderId,
    required this.timestamp,
    required this.isFromMe,
  });

  // Make sure your fromJson factory correctly sets isFromMe
  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final String senderId = json['senderId'] ?? '';
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? '',
      sender: json['sender'] ?? 'Unknown',
      senderId: senderId,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isFromMe: senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}