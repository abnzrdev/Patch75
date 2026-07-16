import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';
import 'problem.dart';

class ProblemBrowser extends StatefulWidget {
  const ProblemBrowser({
    required this.problems,
    required this.onSelected,
    this.progress = const {},
    super.key,
  });

  final List<Problem> problems;
  final ValueChanged<Problem> onSelected;
  final Map<String, String> progress;

  @override
  State<ProblemBrowser> createState() => _ProblemBrowserState();
}

class _ProblemBrowserState extends State<ProblemBrowser> {
  String query = '';
  String difficulty = 'all';
  String progress = 'all';

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final visible = widget.problems.where((problem) {
      final matchesText =
          normalized.isEmpty ||
          problem.title.toLowerCase().contains(normalized) ||
          problem.slug.contains(normalized) ||
          problem.topics.any((topic) => topic.contains(normalized));
      final matchesDifficulty =
          difficulty == 'all' || problem.difficulty == difficulty;
      final state = widget.progress[problem.slug];
      final matchesProgress =
          progress == 'all' ||
          (progress == 'solved' && state == 'solved') ||
          (progress == 'attempted' && state == 'attempted');
      return matchesText && matchesDifficulty && matchesProgress;
    }).toList();
    final solved = widget.progress.values
        .where((state) => state == 'solved')
        .length;

    return Material(
      color: OltColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(OltSpace.x2),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'SEARCH/BLIND75',
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: OltSpace.x2),
            child: Row(
              children: [
                for (final value in const ['all', 'easy', 'medium', 'hard'])
                  Padding(
                    padding: const EdgeInsets.only(right: OltSpace.x1),
                    child: FilterChip(
                      label: Text(value.toUpperCase()),
                      selected: difficulty == value,
                      onSelected: (_) => setState(() => difficulty = value),
                    ),
                  ),
                const SizedBox(width: OltSpace.x2),
                for (final value in const ['attempted', 'solved'])
                  Padding(
                    padding: const EdgeInsets.only(right: OltSpace.x1),
                    child: FilterChip(
                      label: Text(value.toUpperCase()),
                      selected: progress == value,
                      onSelected: (selected) =>
                          setState(() => progress = selected ? value : 'all'),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(OltSpace.x2),
            child: Text(
              'INDEX/${visible.length.toString().padLeft(2, '0')}-VISIBLE · '
              'SOLVED/${solved.toString().padLeft(2, '0')} · DATA/LOCAL',
              style: microStyle,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: OltColors.border),
              itemBuilder: (context, index) {
                final problem = visible[index];
                final state = widget.progress[problem.slug] ?? 'new';
                return ListTile(
                  minTileHeight: 48,
                  shape: const Border(
                    left: BorderSide(color: OltColors.border),
                  ),
                  title: Text(problem.title),
                  subtitle: Text(
                    'REF/BLIND75-${problem.id.toString().padLeft(4, '0')} · '
                    '${problem.topics.join('+').toUpperCase()}',
                    style: microStyle,
                  ),
                  trailing: Text(
                    '${problem.difficulty.toUpperCase()} · ${state.toUpperCase()}',
                    style: microStyle,
                  ),
                  onTap: () => widget.onSelected(problem),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
