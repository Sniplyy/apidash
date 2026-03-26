import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../open_responses_detector.dart';

/// Button that generates and copies a Flutter integration code snippet.
class GenUIExportButton extends StatelessWidget {
  const GenUIExportButton({super.key, required this.jsonBody});

  final String jsonBody;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.code_rounded, size: 16),
      label: const Text('Copy Flutter Code'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () {
        final snippet = generateFlutterSnippet(jsonBody);
        Clipboard.setData(ClipboardData(text: snippet));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Flutter code snippet copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      },
    );
  }
}
