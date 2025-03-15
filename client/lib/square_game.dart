import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:client/player_component.dart';
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SquareGame extends FlameGame with HasKeyboardHandlerComponents {
  late final String playerId;
  late final RawDatagramSocket _socket;
  final _random = Random();
  late final PlayerComponent player;
  List<PlayerComponent> otherPlayers = [];
  final double moveSpeed = 5.0;

  final serverHost = '127.0.0.1';
  final serverPort = 16123;

  SquareGame() : super() {
    playerId = "player_${_random.nextInt(10000)}";
  }

  @override
  Future<void> onLoad() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    _joinServer();
    _socket.listen(_handleServerMessage);

    camera.viewport = FixedResolutionViewport(resolution: Vector2(800, 600));

    return super.onLoad();
  }

  Future<void> _joinServer() async {
    final random = Random();
    final x = random.nextDouble() * 800 - 400;
    final y = random.nextDouble() * 600 - 300;
    player = PlayerComponent(id: playerId, position: Vector2(x, y));
    add(player);
    world.add(PlayerComponent(id: playerId, position: Vector2(x, y)));
    final message = {
      'type': 'JOIN',
      'data': {
        'id': playerId,
        'x': x,
        'y': y,
      }
    };

    _sendMessage(message);
    print('Sent JOIN message to server');
  }

  void _sendMessage(Map<String, dynamic> message) {
    try {
      final encodedMessage = utf8.encode(jsonEncode(message));
      _socket.send(encodedMessage, InternetAddress(serverHost), serverPort);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      final Vector2 movement = Vector2.zero();

      switch (event.logicalKey.keyLabel) {
        case 'W':
          player.position.y -= moveSpeed;
          _sendPositionUpdate();
          return KeyEventResult.handled;
        case 'A':
          player.position.x -= moveSpeed;
          _sendPositionUpdate();
          return KeyEventResult.handled;
        case 'S':
          player.position.y += moveSpeed;
          _sendPositionUpdate();
          return KeyEventResult.handled;
        case 'D':
          player.position.x += moveSpeed;
          _sendPositionUpdate();
          return KeyEventResult.handled;
        default:
      }
      if (movement != Vector2.zero()) {
        player.position.add(movement);

        final message = {
          'type': 'MOVE',
          'data': {
            'id': playerId,
            'x': player.position.x,
            'y': player.position.y,
          }
        };
        _sendMessage(message);

        return KeyEventResult.handled;
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }

  void _sendPositionUpdate() {
    final message = {
      'type': 'MOVE',
      'data': {
        'id': playerId,
        'x': player.position.x,
        'y': player.position.y,
      }
    };
    _sendMessage(message);
  }

  void _handleServerMessage(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket.receive();
    if (datagram == null) return;

    try {
      final message = utf8.decode(datagram.data);
      final json = jsonDecode(message);

      if (json['type'] == 'STATE') {
        final data = json['data'];
        if (data['players'] is List) {
          _updateGameState(List<Map<String, dynamic>>.from(data['players']));
        }
      }
    } catch (e) {
      print('Error handling server message: $e');
    }
  }

  void _updateGameState(List<Map<String, dynamic>> playerList) {
    for (final playerData in playerList) {
      final id = playerData['id'] as String;
      final x = playerData['x'] as double;
      final y = playerData['y'] as double;

      if (id == playerId) continue;

      final existingPlayer = otherPlayers.where((p) => p.id == id).firstOrNull;

      if (existingPlayer != null) {
        existingPlayer.position = Vector2(x, y);
      } else {
        final newPlayer = PlayerComponent(
          id: id,
          position: Vector2(x, y),
        );

        otherPlayers.add(newPlayer);
        add(newPlayer);
      }
    }
  }
}
