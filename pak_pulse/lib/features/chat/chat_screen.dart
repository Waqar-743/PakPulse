import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agents/orchestrator_providers.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crisis.dart';
import '../../providers.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String text;
  final List<Crisis> citedCrises;
  ChatMessage(
      {required this.role, required this.text, this.citedCrises = const []});
}

/// RAG chatbot. Retrieval is plain keyword + sector matching over the local
/// crisis history (active + historical). At this scale that's more accurate
/// and faster than embeddings — we'd ship vectors later if the catalogue ever
/// outgrows in-memory filtering.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Crisis> _retrieve(String query, List<Crisis> corpus) {
    final q = query.toLowerCase();
    if (q.trim().isEmpty) return const [];

    final tokens = q
        .split(RegExp(r'[^a-z0-9\-]+'))
        .where((t) => t.length >= 2)
        .toList();

    int score(Crisis c) {
      int s = 0;
      final hay = '${c.sector} ${c.title} ${c.summaryEn} ${c.type.name}'
          .toLowerCase();
      for (final t in tokens) {
        if (hay.contains(t)) s += 2;
      }
      // Active crises score higher than historical.
      if (c.isActive) s += 3;
      // Recent ones too.
      final hoursOld = DateTime.now().difference(c.detectedAt).inHours;
      if (hoursOld < 6) s += 2;
      if (hoursOld < 24) s += 1;
      return s;
    }

    final ranked = [...corpus]
        .map((c) => (c, score(c)))
        .where((p) => p.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return ranked.take(5).map((p) => p.$1).toList();
  }

  String _buildContext(List<Crisis> crises) {
    if (crises.isEmpty) return 'No matching crisis records in the database.';
    final buf = StringBuffer();
    for (var i = 0; i < crises.length; i++) {
      final c = crises[i];
      buf.writeln('[${i + 1}] ${c.type.label} in ${c.sector}');
      buf.writeln('    severity=${c.severity.label} '
          'confidence=${(c.confidence * 100).toStringAsFixed(0)}% '
          'signals=${c.signalCount} '
          'detected=${c.detectedAt.toIso8601String()} '
          'active=${c.isActive}');
      buf.writeln('    summary: ${c.summaryEn}');
    }
    return buf.toString();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _busy = true;
      _controller.clear();
    });
    _scrollToEnd();

    final active = ref.read(crisisListProvider);
    final historical = ref.read(historicalCrisesProvider);
    final corpus = [...active, ...historical];
    final retrieved = _retrieve(text, corpus);

    final systemPrompt = '''
You are PAK·PULSE Assistant — a crisis-response chatbot for citizens of Pakistan, especially Islamabad.

Use ONLY the crisis records below as your source of truth. If the records don't answer the question, say so plainly — do not invent locations, times, or casualties.

Reply in the same language as the user (English / Urdu / Roman-Urdu). Keep replies short, calm, and practical. When relevant, suggest actions: avoid sector X, use route Y, contact Rescue 1122, etc.

CRISIS RECORDS (most relevant first):
${_buildContext(retrieved)}
''';

    final llm = ref.read(llmClientProvider);
    final reply = await llm.chatComplete(
      systemPrompt: systemPrompt,
      userMessage: text,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        role: 'assistant',
        text: reply,
        citedCrises: retrieved,
      ));
      _busy = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Ask PAK·PULSE'),
        backgroundColor: AppColors.backgroundBase,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
                    ),
            ),
            if (_busy)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Thinking…',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText:
                            'Ask about a sector, a crisis, what to do…',
                        filled: true,
                        fillColor: AppColors.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: AppColors.borderSubtle, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: AppColors.borderSubtle, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.signalBlue.withOpacity(0.14)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(msg.text, style: const TextStyle(fontSize: 14, height: 1.4)),
              if (msg.citedCrises.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text('Sources',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: 4),
                for (final c in msg.citedCrises)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${c.type.label} @ ${c.sector} (${c.severity.label})',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final examples = [
      'Is G-10 safe right now?',
      'Faizabad block hai kya?',
      'What\'s the worst active crisis?',
      'Heatwave warnings today?',
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask anything about live or past crises.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Answers are grounded in PAK·PULSE crisis records — the bot won\'t invent events.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Text('TRY ASKING',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          for (final e in examples)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('• $e',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
