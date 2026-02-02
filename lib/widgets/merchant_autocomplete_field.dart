import 'dart:async';

import 'package:flutter/material.dart';
import '../services/merchant_history_service.dart';
import '../theme/ledgerify_theme.dart';

/// A text field with merchant autocomplete functionality.
///
/// Shows suggestions from merchant history as the user types.
/// When empty/focused, shows recent merchants.
///
/// Features:
/// - Debounced input (200ms) for efficient suggestion fetching
/// - Dropdown styled to match Ledgerify theme
/// - Tapping a suggestion fills the field
class MerchantAutocompleteField extends StatefulWidget {
  final MerchantHistoryService merchantHistoryService;
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  /// Called when a merchant is selected from the autocomplete dropdown.
  /// This is called immediately (without debounce) when user taps a suggestion.
  /// Useful for triggering category auto-suggestion right away.
  final ValueChanged<String>? onMerchantSelected;

  const MerchantAutocompleteField({
    super.key,
    required this.merchantHistoryService,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onMerchantSelected,
  });

  @override
  State<MerchantAutocompleteField> createState() =>
      _MerchantAutocompleteFieldState();
}

class _MerchantAutocompleteFieldState extends State<MerchantAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  Timer? _debounceTimer;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
    } else {
      // Delay hiding to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    widget.onChanged?.call(widget.controller.text);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted && _focusNode.hasFocus) {
        _updateSuggestions();
      }
    });
  }

  void _updateSuggestions() {
    final query = widget.controller.text.trim();
    final suggestions = widget.merchantHistoryService.getSuggestions(
      query,
      limit: 5,
    );

    setState(() {
      _suggestions = suggestions;
    });

    if (suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_isOverlayVisible) {
      // Update existing overlay
      _overlayEntry?.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayVisible = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOverlayVisible = false;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        final colors = LedgerifyColors.of(context);

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + LedgerifySpacing.xs),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: LedgerifyRadius.borderRadiusMd,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      final isFirst = index == 0;
                      final isLast = index == _suggestions.length - 1;

                      return _SuggestionTile(
                        suggestion: suggestion,
                        query: widget.controller.text,
                        isFirst: isFirst,
                        isLast: isLast,
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _removeOverlay();
    widget.onChanged?.call(suggestion);
    // Notify that a merchant was selected from the dropdown
    widget.onMerchantSelected?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        style: LedgerifyTypography.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'e.g., Starbucks, Amazon, Uber',
          hintStyle: LedgerifyTypography.bodyLarge.copyWith(
            color: colors.textTertiary,
          ),
          filled: true,
          fillColor: colors.surfaceHighlight,
          border: const OutlineInputBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: LedgerifyRadius.borderRadiusMd,
            borderSide: BorderSide(
              color: colors.accent,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LedgerifySpacing.lg,
            vertical: LedgerifySpacing.lg,
          ),
        ),
      ),
    );
  }
}

/// Single suggestion tile in the dropdown.
class _SuggestionTile extends StatelessWidget {
  final String suggestion;
  final String query;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.query,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerifySpacing.lg,
          vertical: LedgerifySpacing.md,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colors.divider,
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 18,
              color: colors.textTertiary,
            ),
            LedgerifySpacing.horizontalMd,
            Expanded(
              child: _buildHighlightedText(colors),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the suggestion text with the query portion highlighted.
  Widget _buildHighlightedText(LedgerifyColorScheme colors) {
    if (query.isEmpty) {
      return Text(
        suggestion,
        style: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerSuggestion = suggestion.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();
    final matchIndex = lowerSuggestion.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        suggestion,
        style: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final beforeMatch = suggestion.substring(0, matchIndex);
    final match =
        suggestion.substring(matchIndex, matchIndex + lowerQuery.length);
    final afterMatch = suggestion.substring(matchIndex + lowerQuery.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: LedgerifyTypography.bodyMedium.copyWith(
          color: colors.textPrimary,
        ),
        children: [
          if (beforeMatch.isNotEmpty) TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: LedgerifyTypography.bodyMedium.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (afterMatch.isNotEmpty) TextSpan(text: afterMatch),
        ],
      ),
    );
  }
}
