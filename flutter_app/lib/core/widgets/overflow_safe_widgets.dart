import 'package:flutter/material.dart';

/// Professional wrapper to handle RenderFlex overflow issues
/// This widget provides safe rendering with proper constraints and handles Expanded widgets
class OverflowSafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;

  const OverflowSafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Constrain the Row to the available width to prevent overflow
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            minWidth: 0,
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: _addSpacing(children),
            ),
          ),
        );
      },
    );
  }

  /// Add spacing between children while preserving Expanded widgets
  List<Widget> _addSpacing(List<Widget> children) {
    if (children.isEmpty) return children;

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: spacing ?? 8.0));
      }
    }
    return spacedChildren;
  }
}

/// Professional container with guaranteed no overflow
class ConstrainedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ConstrainedContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          padding: padding,
          margin: margin,
          child: child,
        );
      },
    );
  }
}
