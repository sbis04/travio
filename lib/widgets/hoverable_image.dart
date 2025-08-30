import 'package:flutter/material.dart';

class HoverableImage extends StatefulWidget {
  const HoverableImage({
    super.key,
    required this.translate,
    required this.scale,
    required this.rotate,
    required this.tilt,
    required this.image,
  });

  final Offset translate;
  final double scale;
  final double rotate;
  final double tilt;
  final String image;

  @override
  State<HoverableImage> createState() => _HoverableImageState();
}

class _HoverableImageState extends State<HoverableImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Calculate hover offsets - small adjustments on hover
    final hoverTranslateOffset = _isHovered
        ? Offset(0, -10) // Just lift up slightly on hover
        : Offset.zero;
    final hoverRotateAngle = _isHovered
        ? widget.rotate * 0.2 // Add slight additional rotation
        : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Transform.translate(
        offset: widget.translate,
        child: Transform.scale(
          scale: widget.scale,
          child: Transform.rotate(
            angle: widget.rotate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()
                ..translate(hoverTranslateOffset.dx, hoverTranslateOffset.dy)
                ..rotateZ(hoverRotateAngle),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(widget.tilt), // 3D tilt inward on the right
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: _isHovered ? 0.3 : 0.2),
                        blurRadius: _isHovered ? 25 : 18,
                        offset: Offset(0, _isHovered ? 5 : 2),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: Offset(0, 20),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: _isHovered ? 1.0 : 0.7,
                      child: Image.asset(
                        widget.image,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
