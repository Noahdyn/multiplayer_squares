import 'package:flame/components.dart';
import 'package:flame/palette.dart';

class PlayerComponent extends RectangleComponent {
  final String id;
  PlayerComponent({
    required this.id,
    super.position,
  }) : super(
      size: Vector2(10,10), 
          paint: BasicPalette.lime.paint(),
          anchor: Anchor.center,
        );
}
