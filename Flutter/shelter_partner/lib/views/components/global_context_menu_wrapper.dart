import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shelter_partner/views/components/feedback_submission_dialog.dart';

class GlobalContextMenuWrapper extends StatelessWidget {
  final Widget child;

  const GlobalContextMenuWrapper({super.key, required this.child});

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FeedbackSubmissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only add right-click functionality on web
    if (!kIsWeb) {
      return child;
    }

    return GestureDetector(
      onSecondaryTapDown: (details) {
        // Show context menu on right click (web)
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.feedback_outlined),
                  SizedBox(width: 8),
                  Text('Submit Feedback'),
                ],
              ),
              onTap: () {
                // Use a post-frame callback to show the dialog after the menu closes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showFeedbackDialog(context);
                });
              },
            ),
          ],
        );
      },
      onLongPress: () {
        // Show feedback dialog on long press (mobile fallback)
        if (!kIsWeb) {
          _showFeedbackDialog(context);
        }
      },
      child: child,
    );
  }
}