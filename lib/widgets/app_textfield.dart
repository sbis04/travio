import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.suffixIcon,
    this.textCapitalization,
    this.textInputAction,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? hintText;
  final Widget? suffixIcon;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: widget.readOnly,
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
      textInputAction: widget.textInputAction,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.focusNode.hasFocus
            ? Theme.of(context).colorScheme.primary.withAlpha(40)
            : Theme.of(context).colorScheme.outline.withAlpha(100),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        suffixIcon: widget.suffixIcon,
      ),
    );
  }
}
