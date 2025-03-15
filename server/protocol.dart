import 'dart:convert';

enum MessageType {
  JOIN, // Player joining the game
  MOVE, // Player movement update
  STATE, // Full game state update (sent from server)
  LEAVE // Player leaving the game
}

class GameMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  GameMessage(this.type, this.data);

  static GameMessage? fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);

      final String typeStr = json['type'];
      final MessageType? type = _messageTypeFromString(typeStr);

      if (type == null) {
        print('Invalid message type: $typeStr');
        return null;
      }

      return GameMessage(type, json['data'] ?? {});
    } catch (e) {
      print('Error parsing message: $e');
      return null;
    }
  }

  String toJson() {
    return jsonEncode({
      'type': _messageTypeToString(type),
      'data': data,
    });
  }

  static MessageType? _messageTypeFromString(String typeStr) {
    switch (typeStr) {
      case 'JOIN':
        return MessageType.JOIN;
      case 'MOVE':
        return MessageType.MOVE;
      case 'STATE':
        return MessageType.STATE;
      case 'LEAVE':
        return MessageType.LEAVE;
      default:
        return null;
    }
  }

  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.JOIN:
        return 'JOIN';
      case MessageType.MOVE:
        return 'MOVE';
      case MessageType.STATE:
        return 'STATE';
      case MessageType.LEAVE:
        return 'LEAVE';
    }
  }
}
