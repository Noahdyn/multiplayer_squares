class Player {
  final String id;
  double x;
  double y;
  DateTime lastUpdate;

  Player(this.id, this.x, this.y) : lastUpdate = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
    };
  }
}
