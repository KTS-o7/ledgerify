import 'package:flutter/material.dart';
import '../../theme/ledgerify_theme.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final EdgeInsetsGeometry padding;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.bottom,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.padding = const EdgeInsets.all(LedgerifySpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = LedgerifyColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: automaticallyImplyLeading,
              title: Text(
                title!,
                style: LedgerifyTypography.headlineMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              centerTitle: false,
              actions: actions,
              bottom: bottom,
            ),
      body: Padding(
        padding: padding,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

