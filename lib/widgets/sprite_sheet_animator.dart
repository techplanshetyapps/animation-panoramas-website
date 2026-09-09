import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SpriteSheetAnimator extends StatefulWidget {
  final ui.Image image;
  final int totalFrames;
  final int columns;
  final int rows;
  final Duration duration;

  const SpriteSheetAnimator({
    Key? key,
    required this.image,
    required this.totalFrames,
    required this.columns,
    required this.rows,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  _SpriteSheetAnimatorState createState() => _SpriteSheetAnimatorState();
}

class _SpriteSheetAnimatorState extends State<SpriteSheetAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        int frameIndex = (_controller.value * widget.totalFrames).floor() % widget.totalFrames;
        return CustomPaint(
          painter: SpritePainter(
            image: widget.image,
            frameIndex: frameIndex,
            columns: widget.columns,
            rows: widget.rows,
            totalFrames: widget.totalFrames,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frameIndex;
  final int columns;
  final int rows;
  final int totalFrames;

  SpritePainter({
    required this.image,
    required this.frameIndex,
    required this.columns,
    required this.rows,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double frameWidth = image.width / columns;
    double frameHeight = image.height / rows;

    int col = frameIndex % columns;
    int row = frameIndex ~/ columns;

    Rect srcRect = Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    // Scale and center the frame inside the available widget size
    Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    Paint paint = Paint();
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant SpritePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex;
  }
}