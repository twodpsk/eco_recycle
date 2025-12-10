import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedMascot extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final double topPadding; // 상단 여백 조절

  const AnimatedMascot({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 100,
    this.topPadding = 20, // 기본값을 줄임
  });

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot> with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final Animation<double> _positionAnimation;
  late final Animation<double> _rotationAnimation;

  final List<Widget> _hearts = [];

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOutQuad),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void _addHeart() {
    final Key heartKey = UniqueKey();

    setState(() {
      _hearts.add(
        _HeartAnimation(
          key: heartKey,
          topPadding: widget.topPadding,
          onComplete: () {
            setState(() {
              _hearts.removeWhere((element) => element.key == heartKey);
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height + widget.topPadding, // 여백 반영
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _addHeart,
              child: AnimatedBuilder(
                animation: _moveController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _positionAnimation.value),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  widget.imagePath,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          ..._hearts,
        ],
      ),
    );
  }
}

// ==========================================
// 하트 애니메이션
// ==========================================
class _HeartAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final double topPadding; // 상단 여백 전달

  const _HeartAnimation({
    super.key,
    required this.onComplete,
    this.topPadding = 20,
  });

  @override
  State<_HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<_HeartAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _position;
  late final Animation<double> _scale;

  final double randomAngle = (math.Random().nextDouble() - 0.5) * 0.5;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _position = Tween<double>(begin: 0, end: -100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);

    _controller.forward().whenComplete(widget.onComplete);
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
        return Positioned(
          top: widget.topPadding + _position.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Transform.rotate(
                angle: randomAngle,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.pinkAccent,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
