import 'package:client/square_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';

void main() {
  runApp(const Squares());
}

class Squares extends StatelessWidget {
  const Squares({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: SquareGame(),
    );
  }
}
