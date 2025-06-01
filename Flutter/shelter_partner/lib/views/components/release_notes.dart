import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shelter_partner/models/github_release.dart';

typedef IsVersionGreaterOrEqual = bool Function(
    String version, String minVersion);

class ReleaseNotes extends StatelessWidget {
  final List<GitHubRelease> releases;
  final bool showPreviousVersions;
  final Set<int> expandedReleases;
  final void Function(int index) onToggleExpand;
  final void Function() onToggleShowPrevious;
  // Helper function to compare semantic versions
  bool isVersionGreaterOrEqual(String version, String minVersion) {
    List<int> parse(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v1 = parse(version.replaceAll(RegExp(r'[^0-9.]'), ''));
    final v2 = parse(minVersion.replaceAll(RegExp(r'[^0-9.]'), ''));
    for (int i = 0; i < 3; i++) {
      if ((v1.length > i ? v1[i] : 0) > (v2.length > i ? v2[i] : 0)) {
        return true;
      }
      if ((v1.length > i ? v1[i] : 0) < (v2.length > i ? v2[i] : 0)) {
        return false;
      }
    }
    return true;
  }

  const ReleaseNotes({
    super.key,
    required this.releases,
    required this.showPreviousVersions,
    required this.expandedReleases,
    required this.onToggleExpand,
    required this.onToggleShowPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (releases.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Fetching release notes..."),
          )
        else ...[
          // Show only the most recent release if not showing previous
          ...releases
              .asMap()
              .entries
              .where((entry) =>
                  isVersionGreaterOrEqual(entry.value.version, '2.0.1') &&
                  (!showPreviousVersions ? entry.key == 0 : true))
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onToggleExpand(entry.key),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon and version
                          Container(
                            decoration: BoxDecoration(
                              color: entry.key == 0
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  entry.key == 0
                                      ? Icons.new_releases
                                      : Icons.history,
                                  color: entry.key == 0
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value.version,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: entry.key == 0
                                              ? Colors.blue
                                              : Colors.black87,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${entry.value.publishedAt.day}/${entry.value.publishedAt.month}/${entry.value.publishedAt.year}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  expandedReleases.contains(entry.key)
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: expandedReleases.contains(entry.key)
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: MarkdownBody(
                                data: entry.value.body,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.black87),
                                  h1: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 18,
                                      ),
                                  h2: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                ),
                                onTapLink: (text, href, title) async {
                                  if (href != null) {
                                    final uri = Uri.tryParse(href);
                                    if (uri != null) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          if (releases.length > 1)
            Center(
              child: TextButton.icon(
                icon: Icon(
                  showPreviousVersions
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                ),
                onPressed: onToggleShowPrevious,
                label: Text(
                  showPreviousVersions
                      ? 'Hide Previous Versions'
                      : 'View Previous Versions',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
