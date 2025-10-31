import 'package:flutter/material.dart';

/// Professional loading widget with Material Design 3
class LoadingWidget extends StatelessWidget {
  final String message;
  final bool showSpinner;

  const LoadingWidget({
    super.key,
    this.message = 'Loading...',
    this.showSpinner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner) const CircularProgressIndicator(),
          if (showSpinner) const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
