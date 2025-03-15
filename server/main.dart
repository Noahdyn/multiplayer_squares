import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'game_state.dart';
import 'protocol.dart';

void main() async {
  final gameServer = GameServer();
  await gameServer.start();
}

class GameServer {
  final GameState gameState = GameState();

  final Map<String, InternetAddress> clientAddresses = {};
  final Map<String, int> clientPorts = {};

  final address = InternetAddress("127.0.0.1");
  final port = 16123;
  late RawDatagramSocket socket;

  Timer? updateTimer;

  Future<void> start() async {
    try {
      socket = await RawDatagramSocket.bind(address, port);
      print('Game server started on ${address.address}:$port');

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          handleIncomingPacket();
        }
      });

      updateTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
        broadcastGameState();
      });
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  void handleIncomingPacket() {
    final datagram = socket.receive();
    if (datagram == null) return;

    try {
      final messageString = utf8.decode(datagram.data);
      final message = GameMessage.fromJson(messageString);

      if (message == null) return;
      switch (message.type) {
        case MessageType.JOIN:
          handleJoinMessage(message.data, datagram.address, datagram.port);
        case MessageType.MOVE:
          handleMoveMessage(message.data);
        case MessageType.LEAVE:
          handleLeaveMessage(message.data);
        default:
      }
    } catch (e) {
      print('Error processing packet: $e');
    }
  }

  void handleJoinMessage(
    Map<String, dynamic> data,
    InternetAddress address,
    int port,
  ) {
    final playerId = data['id'];

    if (playerId == null) {
      print('JOIN message missing player ID');
      return;
    }

    clientAddresses[playerId] = address;
    clientPorts[playerId] = port;

    final x = data['x']?.toDouble() ?? 0.0;
    final y = data['y']?.toDouble() ?? 0.0;
    gameState.updatePlayer(playerId, x, y);

    print('Player $playerId joined the game');
  }

  void handleMoveMessage(Map<String, dynamic> data) {
    final playerId = data['id'];
    final x = data['x']?.toDouble();
    final y = data['y']?.toDouble();

    if (playerId == null || x == null || y == null) {
      print('MOVE message missing required fields');
      return;
    }

    gameState.updatePlayer(playerId, x, y);
  }

  void handleLeaveMessage(Map<String, dynamic> data) {
    final playerId = data['id'];

    if (playerId == null) {
      print('LEAVE message missing player ID');
      return;
    }

    gameState.removePlayer(playerId);
    clientAddresses.remove(playerId);
    clientPorts.remove(playerId);

    print('Player $playerId left the game');
  }

  void broadcastGameState() {
    if (clientAddresses.isEmpty) return;

    final stateMessage = GameMessage(MessageType.STATE, gameState.toJson());

    final encodedMessage = utf8.encode(stateMessage.toJson());

    for (final entry in clientAddresses.entries) {
      final playerId = entry.key;
      final address = entry.value;
      final port = clientPorts[playerId];

      if (port != null) {
        socket.send(encodedMessage, address, port);
      }
    }
  }
}
