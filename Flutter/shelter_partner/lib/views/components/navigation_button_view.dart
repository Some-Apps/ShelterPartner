import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// NavigationButton widget using GoRouter
class NavigationButton extends StatelessWidget {
  final String title;
  final String route;  // Route URL to navigate

  const NavigationButton({super.key, required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(route);  // Use GoRouter to navigate
      },
    );
  }
}
