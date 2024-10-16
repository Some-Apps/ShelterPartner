import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// NavigationButton widget using GoRouter
class NavigationButton extends StatelessWidget {
  final String title;
  final String route; // Route URL to navigate
  final Object? extra; // Optional extra data to pass

  const NavigationButton({
    Key? key,
    required this.title,
    required this.route,
    this.extra, // Initialize extra
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Pass the extra parameter when navigating
        context.push(route, extra: extra);
      },
    );
  }
}
