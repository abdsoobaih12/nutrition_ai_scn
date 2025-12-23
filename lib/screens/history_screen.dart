import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ai_scn/models/analysis_result.dart';
import 'package:ai_scn/services/history_service.dart';
import 'package:ai_scn/screens/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();
  List<AnalysisResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _historyService.getHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  Color _sectionColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('harmful') ||
        lower.contains('controversial') ||
        lower.contains('drawbacks') ||
        lower.contains('risks')) {
      return Colors.orangeAccent;
    }
    if (lower.contains('benefit')) {
      return Colors.greenAccent;
    }
    return Colors.white;
  }

  List<_Section> _splitSections(String markdown) {
    final lines = markdown.split('\n');
    final sections = <_Section>[];
    String? currentTitle;
    final buffer = StringBuffer();

    void pushSection() {
      final title = currentTitle;
      final content = buffer.toString().trim();

      if (title != null && content.isNotEmpty) {
        sections.add(_Section(title: title, content: content));
      } else if (content.isNotEmpty) {
        sections.add(_Section(title: 'Details', content: content));
      }

      buffer.clear();
    }

    for (final line in lines) {
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)').firstMatch(line);
      if (headingMatch != null) {
        pushSection();
        currentTitle = headingMatch.group(2) ?? 'Section';
      } else {
        buffer.writeln(line);
      }
    }

    pushSection();
    return sections.isEmpty
        ? [_Section(title: 'Details', content: markdown)]
        : sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text(
                      'Are you sure you want to delete all history?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _historyService.clearHistory();
                  _loadHistory();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your scan results will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final result = _history[index];
                      final file = File(result.imagePath);
                      final sections = _splitSections(result.analysisResult);
                      final moreCount = sections.length - 1;
                      final sectionText = moreCount > 1 ? 'sections' : 'section';
                      final moreSections = sections.length > 1
                          ? '+ $moreCount more $sectionText'
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(
                                  imagePath: result.imagePath,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: file.existsSync()
                                          ? Image.file(
                                              file,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.black12,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white54,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatTimestamp(result.timestamp),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.white54,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (sections.isNotEmpty)
                                            Text(
                                              sections.first.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: _sectionColor(
                                                      sections.first.title,
                                                    ),
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (sections.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    sections.first.content,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white70,
                                        ),
                                    ),
                                    if (sections.length > 1) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        moreSections,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white54,
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                  ],
                                ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Section {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;
}
