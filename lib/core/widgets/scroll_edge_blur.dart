import 'dart:ui';

import 'package:flutter/material.dart';

/// Adds a subtle blur to scrolling content at its viewport edges.
///
/// The overlay ignores pointer events and stays inside the supplied scroll
/// area, so surrounding navigation controls remain sharp and interactive.
class ScrollEdgeBlur extends StatelessWidget {
  const ScrollEdgeBlur({
    super.key,
    required this.child,
    required this.controller,
    this.topExtent = 112,
    this.bottomExtent = 160,
  });

  final Widget child;
  final ScrollController controller;
  final double topExtent;
  final double bottomExtent;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: topExtent,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final isScrollingPastTop =
                controller.hasClients && controller.offset > 1;
            if (!isScrollingPastTop) return const SizedBox.shrink();
            return IgnorePointer(
              child: _BlurredEdge(top: true, extent: topExtent),
            );
          },
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: bottomExtent,
        child: IgnorePointer(
          child: _BlurredEdge(top: false, extent: bottomExtent),
        ),
      ),
    ],
  );
}

class _BlurredEdge extends StatelessWidget {
  const _BlurredEdge({required this.top, required this.extent});

  final bool top;
  final double extent;

  static const _layers = [
    (1.0, 0.55),
    (0.8, 0.75),
    (0.6, 1.0),
    (0.4, 1.3),
    (0.2, 1.6),
  ];

  @override
  Widget build(BuildContext context) {
    final intensity = top ? 1.0 : 1.35;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final layer in _layers)
          Positioned(
            left: 0,
            right: 0,
            height: extent * layer.$1,
            top: top ? 0 : null,
            bottom: top ? null : 0,
            child: _BlurLayer(sigma: layer.$2 * intensity),
          ),
      ],
    );
  }
}

class _BlurLayer extends StatelessWidget {
  const _BlurLayer({required this.sigma});

  final double sigma;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 0, sigmaY: sigma),
      child: const ColoredBox(color: Color(0x01000000)),
    ),
  );
}
