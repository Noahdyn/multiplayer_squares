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

  late RawDatagramSocket socket;

  Timer? updateTimer;

  // Start the server
  Future<void> start() async {
    // Bind to UDP socket
    var address = InternetAddress("127.0.0.1");
    int port = 16123;

    try {
      socket = await RawDatagramSocket.bind(address, port);
      print('Game server started on ${address.address}:$port');

      // Set up socket event handling
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          handleIncomingPacket();
        }
      });

      // Start periodic game state updates (10 times per second)
      updateTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
        broadcastGameState();
      });
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  // Handle incoming UDP packets
  void handleIncomingPacket() {
    final datagram = socket.receive();
    if (datagram == null) return;

    try {
      final messageString = utf8.decode(datagram.data);
      final message = GameMessage.fromJson(messageString);

      if (message == null) return;

      // Process message based on type
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

  // Handle JOIN message
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

    // Store client address for future communication
    clientAddresses[playerId] = address;
    clientPorts[playerId] = port;

    // Add player to game state with initial position
    final x = data['x']?.toDouble() ?? 0.0;
    final y = data['y']?.toDouble() ?? 0.0;
    gameState.updatePlayer(playerId, x, y);

    print('Player $playerId joined the game');
  }

  // Handle MOVE message
  void handleMoveMessage(Map<String, dynamic> data) {
    final playerId = data['id'];
    final x = data['x']?.toDouble();
    final y = data['y']?.toDouble();

    if (playerId == null || x == null || y == null) {
      print('MOVE message missing required fields');
      return;
    }

    // Update player position
    gameState.updatePlayer(playerId, x, y);
  }

  // Handle LEAVE message
  void handleLeaveMessage(Map<String, dynamic> data) {
    final playerId = data['id'];

    if (playerId == null) {
      print('LEAVE message missing player ID');
      return;
    }

    // Remove player from game state
    gameState.removePlayer(playerId);
    clientAddresses.remove(playerId);
    clientPorts.remove(playerId);

    print('Player $playerId left the game');
    print("adding player");
  }

  // Broadcast game state to all connected clients
  void broadcastGameState() {
    // Don't send updates if no players
    if (clientAddresses.isEmpty) return;

    // Create STATE message with current game state
    final stateMessage = GameMessage(MessageType.STATE, gameState.toJson());

    final encodedMessage = utf8.encode(stateMessage.toJson());

    // Send to all connected clients
    for (final entry in clientAddresses.entries) {
      final playerId = entry.key;
      final address = entry.value;
      final port = clientPorts[playerId];

      if (port != null) {
        socket.send(encodedMessage, address, port);
      }
    }
  }

  // Stop the server
  void stop() {
    updateTimer?.cancel();
    socket.close();
    print('Game server stopped');
  }
}
