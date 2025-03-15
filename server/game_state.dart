import 'player.dart';

class GameState {
  final Map<String, Player> players = {};

  void updatePlayer(String id, double x, double y) {
    if (players.containsKey(id)) {
      players[id]!.x = x;
      players[id]!.y = y;
      players[id]!.lastUpdate = DateTime.now();
    } else {
      players[id] = Player(id, x, y);
    }
  }

  void removePlayer(String id) {
    players.remove(id);
  }

  Map<String, dynamic> toJson() {
    return {
      'players': players.values.map((player) => player.toJson()).toList(),
    };
  }
}
