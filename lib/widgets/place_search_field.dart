import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:travio/models/place.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/widgets/app_textfield.dart';

enum SelectionTrigger { mouseClick, enterKey }

class PlaceSearchField extends StatefulWidget {
  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onPlaceSelected,
    this.hintText = 'Where would you like to go?',
    this.onChanged,
    this.onSubmitted,
    this.isSearching = false,
    this.overlayHeight = 300.0,
    this.itemHeight = 60.0,
    this.debounceDelay = const Duration(milliseconds: 300),
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(Place selectedPlace) onPlaceSelected;
  final String hintText;
  final VoidCallback? onChanged;
  final Function(String)? onSubmitted;
  final bool isSearching;
  final double overlayHeight;
  final double itemHeight;
  final Duration debounceDelay;

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _overlayEntry;
  List<Place> _searchedDestinations = [];
  int _highlightedIndex = -1;
  bool _isLoading = false;

  Place? _selectedPlace;

  bool get _isSearching => _isLoading || widget.isSearching;

  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(() {
      if (!mounted) return;

      if (widget.focusNode.hasFocus) {
        _showOverlay();
      } else {
        _highlightedIndex = -1;
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    EasyDebounce.cancel('place-search');
    _scrollController.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.onChanged?.call();
    setState(() => _selectedPlace = null);

    if (query.isEmpty) {
      EasyDebounce.cancel('place-search');
      setState(() {
        _searchedDestinations.clear();
        _isLoading = false;
        _highlightedIndex = -1;
      });
      _updateOverlay();
      return;
    }

    // Debounce search requests
    EasyDebounce.debounce(
      'place-search',
      widget.debounceDelay,
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final destinations = await PlacesService.searchDestinations(query);

      if (mounted) {
        setState(() {
          _searchedDestinations = destinations;
          _highlightedIndex = destinations.isNotEmpty ? 0 : -1;
        });
        _updateOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchedDestinations.clear();
          _highlightedIndex = -1;
        });
        _updateOverlay();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemSelected(int index, SelectionTrigger trigger) {
    if (index < 0 || index >= _searchedDestinations.length) return;

    final selectedPlace = _searchedDestinations[index];
    widget.controller.text = selectedPlace.name;
    setState(() => _selectedPlace = selectedPlace);
    widget.onPlaceSelected(selectedPlace);
    widget.focusNode.unfocus();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: _buildOverlay(),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_highlightedIndex != -1 &&
            _highlightedIndex < _searchedDestinations.length) {
          _onItemSelected(_highlightedIndex, SelectionTrigger.enterKey);
          return KeyEventResult.handled;
        } else if (widget.onSubmitted != null) {
          widget.onSubmitted!(widget.controller.text);
          return KeyEventResult.handled;
        }
      }

      if (_searchedDestinations.isEmpty) {
        return KeyEventResult.ignored;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1)
              .clamp(0, _searchedDestinations.length - 1);
        });
        _scrollToSelected(isDown: true);
        _updateOverlay();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1)
              .clamp(0, _searchedDestinations.length - 1);
        });
        _scrollToSelected(isDown: false);
        _updateOverlay();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _scrollToSelected({required bool isDown}) {
    if (_highlightedIndex == -1) return;

    final scrollPosition = _highlightedIndex * widget.itemHeight;
    final viewportHeight = widget.overlayHeight;

    if (isDown &&
        scrollPosition - _scrollController.offset >=
            viewportHeight - widget.itemHeight) {
      _scrollController
          .jumpTo(scrollPosition - viewportHeight + widget.itemHeight);
    } else if (!isDown && scrollPosition < _scrollController.offset) {
      _scrollController.jumpTo(scrollPosition);
    }
  }

  Widget _buildOverlay() {
    if (!mounted || (_searchedDestinations.isEmpty && !_isSearching)) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.overlayHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isSearching
              ? _buildLoadingState()
              : _searchedDestinations.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching destinations...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.search_off,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'No destinations found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _searchedDestinations.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final place = _searchedDestinations[index];
          final isHighlighted = _highlightedIndex == index;

          return InkWell(
            borderRadius: BorderRadius.only(
              topLeft: index == 0 ? Radius.circular(12) : Radius.zero,
              topRight: index == 0 ? Radius.circular(12) : Radius.zero,
              bottomLeft: index == _searchedDestinations.length - 1
                  ? Radius.circular(12)
                  : Radius.zero,
              bottomRight: index == _searchedDestinations.length - 1
                  ? Radius.circular(12)
                  : Radius.zero,
            ),
            onTap: () => _onItemSelected(index, SelectionTrigger.mouseClick),
            child: Container(
              height: widget.itemHeight,
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primary.withAlpha(50)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  _buildPlaceImage(place),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (place.displayAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            place.displayAddress,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(150),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _getPlaceIcon(place.types),
                    color: Theme.of(context).colorScheme.primary.withAlpha(150),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceImage(Place place) {
    // Use preloaded photo URLs from search results
    if (place.photoUrls.isNotEmpty) {
      final photoUrl = place.photoUrls.first;
      return Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(100),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: 60,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _buildFallbackIcon(place),
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
          ),
        ),
      );
    } else {
      return _buildFallbackIcon(place);
    }
  }

  Widget _buildFallbackIcon(Place place) {
    return Container(
      width: 60,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(100),
          width: 1,
        ),
      ),
      child: Icon(
        _getPlaceIcon(place.types),
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      ),
    );
  }

  IconData _getPlaceIcon(List<String> types) {
    if (types.contains('country')) return Icons.map;
    if (types.contains('locality')) return Icons.location_city;
    if (types.contains('administrative_area_level_1')) return Icons.map;
    if (types.contains('tourist_attraction')) return Icons.attractions;
    if (types.contains('natural_feature')) return Icons.landscape;
    if (types.contains('airport')) return Icons.flight;
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: AppTextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: _onSearchChanged,
            onSubmitted: widget.onSubmitted,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            hintText: _isSearching ? 'Searching...' : widget.hintText,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _isSearching ||
                        widget.controller.text.isEmpty ||
                        _selectedPlace == null
                    ? null
                    : () => widget.onSubmitted?.call(widget.controller.text),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  disabledBackgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(100),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSearching
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Start Planning',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            )),
        // child: TextField(
        //   controller: widget.controller,
        //   focusNode: widget.focusNode,
        //   onChanged: _onSearchChanged,
        //   onSubmitted: widget.onSubmitted,
        //   textCapitalization: TextCapitalization.words,
        //   textInputAction: TextInputAction.search,
        //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //         color: Theme.of(context).colorScheme.onSurface,
        //       ),
        //   decoration: InputDecoration(
        //     filled: true,
        //     fillColor: widget.focusNode.hasFocus
        //         ? Theme.of(context).colorScheme.primary.withAlpha(40)
        //         : Theme.of(context).colorScheme.outline.withAlpha(100),
        //     hintText: _isSearching ? 'Searching...' : widget.hintText,
        //     hintStyle: TextStyle(
        //       color: Theme.of(context)
        //           .colorScheme
        //           .onSurface
        //           .withValues(alpha: 0.6),
        //     ),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(20),
        //       borderSide: BorderSide(
        //         color: Theme.of(context).colorScheme.outline,
        //         width: 2,
        //       ),
        //     ),
        //     enabledBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(20),
        //       borderSide: BorderSide(
        //         color: Theme.of(context).colorScheme.outline,
        //         width: 2,
        //       ),
        //     ),
        //     focusedBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(20),
        //       borderSide: BorderSide(
        //         color: Theme.of(context).colorScheme.primary,
        //         width: 2,
        //       ),
        //     ),
        //     contentPadding: const EdgeInsets.symmetric(
        //       horizontal: 24,
        //       vertical: 20,
        //     ),
        //     suffixIcon: Padding(
        //       padding: const EdgeInsets.only(right: 8),
        //       child: ElevatedButton(
        //         onPressed: _isSearching ||
        //                 widget.controller.text.isEmpty ||
        //                 _selectedPlace == null
        //             ? null
        //             : () => widget.onSubmitted?.call(widget.controller.text),
        //         style: ElevatedButton.styleFrom(
        //           elevation: 2,
        //           backgroundColor: Theme.of(context).colorScheme.primary,
        //           disabledBackgroundColor:
        //               Theme.of(context).colorScheme.primary.withAlpha(100),
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 24,
        //             vertical: 16,
        //           ),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(15),
        //           ),
        //         ),
        //         child: _isSearching
        //             ? SizedBox(
        //                 width: 16,
        //                 height: 16,
        //                 child: CircularProgressIndicator(
        //                   strokeWidth: 2,
        //                   valueColor: AlwaysStoppedAnimation<Color>(
        //                     Theme.of(context).colorScheme.onPrimary,
        //                   ),
        //                 ),
        //               )
        //             : Text(
        //                 'Start Planning',
        //                 style: TextStyle(
        //                   color: Theme.of(context).colorScheme.onPrimary,
        //                   fontWeight: FontWeight.w600,
        //                   fontSize: 14,
        //                 ),
        //               ),
        //       ),
        //     ),
        //   ),
        // ),
      ),
    );
  }
}
