import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 450),
  });

  final Widget front;
  final Widget back;
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  bool get _showingFront => _controller.value < 0.5;

  void _toggle() {
    if (_controller.isAnimating) return;
    if (_showingFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, _) {
          final angle = _animation.value * math.pi;
          final showFront = angle < math.pi / 2;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // perspective
            ..rotateY(angle);
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: showFront
                ? widget.front
                // Counter-rotate the back so its content reads correctly.
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}
