import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/ledgerify_theme.dart';

/// SearchFilterBar - Ledgerify Design Language
///
/// An expandable search bar for the Home screen AppBar.
///
/// Two states:
/// 1. Collapsed (default): Shows title with search and filter icons
/// 2. Expanded: Shows text field with back arrow and clear button
///
/// Features:
/// - Smooth expand/collapse animation (200ms)
/// - Debounced search input (300ms)
/// - Filter badge indicator when filters are active
/// - Auto-focus when expanded
class SearchFilterBar extends StatefulWidget {
  /// The title to display when collapsed (e.g., "January 2026")
  final String title;

  /// Current search query value
  final String searchQuery;

  /// Whether any filters are currently active
  final bool hasActiveFilters;

  /// Called when search text changes (debounced 300ms)
  final ValueChanged<String> onSearchChanged;

  /// Called when filter button is tapped
  final VoidCallback onFilterTap;

  /// Optional: Called when title is tapped
  final VoidCallback? onTitleTap;

  const SearchFilterBar({
    super.key,
    required this.title,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onFilterTap,
    this.onTitleTap,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller with external search query changes
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animationController.forward();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _collapse() {
    _focusNode.unfocus();
    _animationController.reverse().then((_) {
      setState(() => _isExpanded = false);
    });
    // Clear search when collapsing
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      widget.onSearchChanged('');
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Collapsed state
            Opacity(
              opacity: 1.0 - _expandAnimation.value,
              child: IgnorePointer(
                ignoring: _isExpanded,
                child: _buildCollapsedState(colors),
              ),
            ),
            // Expanded state
            Opacity(
              opacity: _expandAnimation.value,
              child: IgnorePointer(
                ignoring: !_isExpanded,
                child: _buildExpandedState(colors),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedState(LedgerifyColorScheme colors) {
    return Row(
      children: [
        // Title (tappable if callback provided)
        Expanded(
          child: widget.onTitleTap != null
              ? GestureDetector(
                  onTap: widget.onTitleTap,
                  child: _buildTitle(colors),
                )
              : _buildTitle(colors),
        ),

        // Search icon button
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: colors.textPrimary,
          ),
          onPressed: _expand,
          tooltip: 'Search',
        ),

        // Filter icon button with badge
        _buildFilterButton(colors),
      ],
    );
  }

  Widget _buildTitle(LedgerifyColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: LedgerifyTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (widget.onTitleTap != null) ...[
          LedgerifySpacing.horizontalXs,
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedState(LedgerifyColorScheme colors) {
    return Row(
      children: [
        // Back arrow
        IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
          ),
          onPressed: _collapse,
          tooltip: 'Close search',
        ),

        // Search text field
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: LedgerifyRadius.borderRadiusMd,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: LedgerifyTypography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                hintStyle: LedgerifyTypography.bodyLarge.copyWith(
                  color: colors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: LedgerifySpacing.md,
                  vertical: LedgerifySpacing.sm,
                ),
                // Clear button
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
                        tooltip: 'Clear',
                      )
                    : Icon(
                        Icons.search_rounded,
                        color: colors.textTertiary,
                        size: 20,
                      ),
              ),
            ),
          ),
        ),

        LedgerifySpacing.horizontalSm,

        // Filter button (always visible)
        _buildFilterButton(colors),
      ],
    );
  }

  Widget _buildFilterButton(LedgerifyColorScheme colors) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.filter_list_rounded,
            color: colors.textPrimary,
          ),
          if (widget.hasActiveFilters)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onPressed: widget.onFilterTap,
      tooltip: 'Filter',
    );
  }
}
