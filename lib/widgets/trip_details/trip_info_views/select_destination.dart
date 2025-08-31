import 'package:flutter/material.dart';
import 'package:travio/models/place.dart';
import 'package:travio/widgets/place_search_field.dart';

class SelectDestinationView extends StatelessWidget {
  const SelectDestinationView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onPlaceSelected,
    required this.onSubmitted,
    required this.isSearching,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(Place) onPlaceSelected;
  final Function(String) onSubmitted;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 550),
      child: PlaceSearchField(
        controller: controller,
        focusNode: focusNode,
        isSearching: isSearching,
        onPlaceSelected: onPlaceSelected,
        onSubmitted: onSubmitted,
        hintText: 'Where would you like to go? ✈️',
      ),
    );
  }
}
