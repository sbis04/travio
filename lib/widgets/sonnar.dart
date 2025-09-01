import 'dart:async';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:uuid/v4.dart';

const kDefaultToastDuration = Duration(seconds: 5);

/// Variants available for the [AppToast] widget.
enum AppToastVariant { primary, destructive }

/// A customizable toast notification widget.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    this.id,
    this.title,
    this.description,
    this.action,
    this.variant = AppToastVariant.primary,
    this.duration,
    this.actionLabel,
    this.onClose,
  });

  final String? id;
  final Widget? title;
  final Widget? description;
  final Widget? action;
  final AppToastVariant variant;
  final Duration? duration;
  final VoidCallback? onClose;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = Theme.of(context).colorScheme.surface;
    final titleTextColor = variant == AppToastVariant.primary
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: PointerInterceptor(
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: titleTextColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: titleTextColor.withAlpha(20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 8,
                top: 8,
                bottom: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 300, // Leave space for the button
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (title != null)
                                    DefaultTextStyle(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: titleTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      child: title!,
                                    ),
                                  if (description != null) ...[
                                    if (title != null) SizedBox(height: 2),
                                    DefaultTextStyle(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      child: description!,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (action != null) ...[
                            SizedBox(width: 8),
                            action!,
                          ],
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose ?? () {},
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(180),
                      ),
                    ),
                  ),
                  // TextButton(
                  //   onPressed: onClose ?? () {},
                  //   style: TextButton.styleFrom(
                  //     backgroundColor: Theme.of(context)
                  //         .colorScheme
                  //         .outline
                  //         .withValues(alpha: 0.5),
                  //     foregroundColor: Theme.of(context).colorScheme.onSurface,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //   ),
                  //   child: Text(
                  //     actionLabel ?? "Close",
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //           color: Theme.of(context)
                  //               .colorScheme
                  //               .onSurface
                  //               .withValues(alpha: 0.7),
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ToastInfo {
  ToastInfo({
    required this.id,
    required this.toast,
    required this.controller,
    this.visible = true,
  });

  final String id;
  final AppToast toast;
  final AnimationController controller;
  bool visible;
  Timer? timer;
  bool isHovered = false;
}

/// A widget that manages and displays toasts within the widget tree.
class AppSonnar extends StatefulWidget {
  const AppSonnar({
    super.key,
    required this.child,
    this.visibleToastsAmount = 3,
    this.gap = 8.0,
    this.scaleFactor = 0.05,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16),
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final Widget child;
  final int visibleToastsAmount;
  final double gap;
  final double scaleFactor;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;
  final Duration animationDuration;

  @override
  State<AppSonnar> createState() => AppSonnarState();

  static AppSonnarState of(BuildContext context) {
    final provider = context.findAncestorStateOfType<AppSonnarState>();
    if (provider == null) {
      throw FlutterError('''Could not find AppToast in the widget tree.''');
    }
    return provider;
  }
}

class AppSonnarState extends State<AppSonnar> with TickerProviderStateMixin {
  final _toasts = <ToastInfo>[];

  @override
  void dispose() {
    for (final toast in _toasts) {
      toast.timer?.cancel();
      toast.controller.dispose();
    }
    super.dispose();
  }

  void _startTimer(ToastInfo toastInfo) {
    toastInfo.timer?.cancel();
    if (!toastInfo.isHovered) {
      final effectiveDuration =
          toastInfo.toast.duration ?? kDefaultToastDuration;
      toastInfo.timer = Timer(effectiveDuration, () {
        hide(toastInfo.id);
      });
    }
  }

  String show(AppToast toast) {
    final controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    final effectiveId = toast.id ?? UuidV4().generate();
    final toastInfo = ToastInfo(
      id: effectiveId,
      toast: toast,
      controller: controller,
    );

    if (_toasts.length >= widget.visibleToastsAmount) {
      hide(_toasts.first.id);
    }

    setState(() {
      _toasts.add(toastInfo);
    });

    controller.forward();
    _startTimer(toastInfo);

    return effectiveId;
  }

  Future<void> hide(String id) async {
    final toastInfo = _toasts.firstWhereOrNull((toast) => toast.id == id);
    if (toastInfo == null) return;

    setState(() {
      toastInfo.visible = false;
    });

    toastInfo.timer?.cancel();
    toastInfo.timer = null;

    await toastInfo.controller.reverse();
    toastInfo.controller.dispose();

    setState(() {
      _toasts.remove(toastInfo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: widget.alignment,
      children: [
        widget.child,
        Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _toasts.mapIndexed((index, toastInfo) {
              final x = widget.scaleFactor * (_toasts.length - 1 - index);
              final scaleX = 1.0 - x;

              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: toastInfo.controller,
                  curve: Curves.easeOut,
                ),
              );

              final scaleAnimation = Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: toastInfo.controller,
                  curve: Curves.easeOut,
                ),
              );

              final fadeAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: toastInfo.controller,
                  curve: Curves.easeOut,
                ),
              );

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _toasts.length - 1 ? widget.gap : 0,
                ),
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      toastInfo.isHovered = true;
                      toastInfo.timer?.cancel();
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      toastInfo.isHovered = false;
                      _startTimer(toastInfo);
                    });
                  },
                  child: Transform.scale(
                    scale: scaleX,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: AppToast(
                            key: ValueKey(toastInfo.id),
                            id: toastInfo.id,
                            title: toastInfo.toast.title,
                            description: toastInfo.toast.description,
                            action: toastInfo.toast.action,
                            variant: toastInfo.toast.variant,
                            duration: toastInfo.toast.duration,
                            onClose: () => hide(toastInfo.id),
                            actionLabel: toastInfo.toast.actionLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
