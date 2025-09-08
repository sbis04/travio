import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.count = 0,
    this.icon,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final int count;
  final IconData? icon;
  final bool initiallyExpanded;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with TickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: 300.ms,
      curve: Curves.easeInOut,
      padding: _isExpanded
          ? const EdgeInsets.all(0)
          : const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: _isExpanded
              ? BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )
              : BorderRadius.circular(16),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
            left: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: _isExpanded ? 0.001 : 1,
            ),
            right: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: _isExpanded ? 0.001 : 1,
            ),
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: _isExpanded ? 0.001 : 1,
            ),
          ),
          boxShadow: _isExpanded
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Header
            Material(
              color: Colors.transparent,
              child: InkWell(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon
                      if (widget.icon != null)
                        Icon(
                          widget.icon!,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),

                      if (widget.icon != null) const SizedBox(width: 12),

                      // Title and count
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            if (widget.count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.count.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Expand/collapse icon
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
