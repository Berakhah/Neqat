import 'package:flutter/material.dart';

class ShimmerLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? placeholder;

  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    if (placeholder != null) {
      return placeholder!;
    }

    return ShimmerEffect(
      child: child,
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
              ],
              stops: const [0.1, 0.3, 0.4],
              begin: Alignment(_animation.value, -1),
              end: const Alignment(-1, 1),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
} 