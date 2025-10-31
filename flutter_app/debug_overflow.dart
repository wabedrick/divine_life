import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Add this to main.dart in the main() function to enable debug mode
void enableDebugMode() {
  debugPaintSizeEnabled = false; // Set to true to see widget boundaries

  // This will show overflow indicators in red and yellow
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is RenderFlex) {
      // print('OVERFLOW DETECTED: ${details.exception}');
      // print('Context: ${details.context}');
    }
    FlutterError.presentError(details);
  };
}

// Wrapper to catch overflow exceptions
class OverflowSafeWidget extends StatelessWidget {
  final Widget child;

  const OverflowSafeWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(width: constraints.maxWidth, child: child);
      },
    );
  }
}
