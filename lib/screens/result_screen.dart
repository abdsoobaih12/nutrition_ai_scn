import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:ai_scn/models/analysis_result.dart';
import 'package:ai_scn/services/history_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const String _defaultEndpoint =
      'http://192.168.1.107:4000/api/analyze'; // Replace with deployed URL.

  bool _isLoading = true;
  String? _analysisText;
  String? _errorMessage;
  final _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    final file = File(widget.imagePath);
    final exists = await file.exists();

    if (!exists) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Image file could not be found.';
      });
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final encoded = base64Encode(bytes);

      final uri = Uri.parse(
        const String.fromEnvironment(
          'ANALYSIS_ENDPOINT',
          defaultValue: _defaultEndpoint,
        ),
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageBase64': encoded}),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final resultText =
            decoded['result']?.toString() ?? 'No analysis returned.';
        setState(() {
          _analysisText = resultText;
          _isLoading = false;
        });

        // Save to history
        try {
          final analysisResult = AnalysisResult.create(
            imagePath: widget.imagePath,
            analysisResult: resultText,
          );
          await _historyService.saveAnalysis(analysisResult);
        } catch (e) {
          // Log error but don't show to user
          debugPrint('Failed to save analysis to history: $e');
        }
      } else {
        setState(() {
          _errorMessage =
              'Server error (${response.statusCode}): ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to analyze image: $e';
        _isLoading = false;
      });
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
    final lines = LineSplitter.split(markdown).toList();
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

  Widget _buildAnalysisView(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Analyzing ingredients...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _startAnalysis();
            },
            child: const Text('Try again'),
          ),
        ],
      );
    }

    final sections = _splitSections(_analysisText ?? '');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _sectionColor(section.title),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: section.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white70, height: 1.4),
                      listBullet: const TextStyle(color: Colors.white70),
                      unorderedListAlign: WrapAlignment.start,
                      blockSpacing: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan result')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Captured ingredient list',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.contain, height: 220)
                  : Container(
                      height: 220,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Text('Image unavailable'),
                    ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              widget.imagePath,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildAnalysisView(context)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Scan again'),
            ),
          ],
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
