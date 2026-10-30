import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/contracts/intelligence_service.dart';
import '../../core/contracts/session_provider.dart';

class ChatMessageItem {
  final String senderId;
  final String senderName;
  final String originalText;
  final ProcessedMessage processed;
  final int timestamp;
  bool isExpanded;

  ChatMessageItem({
    required this.senderId,
    required this.senderName,
    required this.originalText,
    required this.processed,
    required this.timestamp,
    this.isExpanded = false,
  });
}

class ChatScreen extends StatefulWidget {
  final SessionProvider sessionProvider;
  final IntelligenceService intelligenceService;

  const ChatScreen({
    super.key,
    required this.sessionProvider,
    required this.intelligenceService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessageItem> _messages = [];
  String _preferredLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _seedInitialDemoMessages();
  }

  void _seedInitialDemoMessages() async {
    // Demonstrating Telugu incoming message with receiver-side translation and extractive summary
    const sampleTelugu = 'వంతెన కూలిపోయింది మరియు ముగ్గురు వ్యక్తులు చిక్కుకున్నారు. నీరు మరియు ఆహారం లేదు. మేము వెంటనే సహాయం కోరుతున్నాము.';
    final processed = await widget.intelligenceService.processMessage(
      originalText: sampleTelugu,
      preferredLanguage: _preferredLanguage,
    );

    setState(() {
      _messages.add(ChatMessageItem(
        senderId: 'PEER_RAVI',
        senderName: 'Ravi (Peer)',
        originalText: sampleTelugu,
        processed: processed,
        timestamp: DateTime.now().millisecondsSinceEpoch - 120000,
      ));
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final processed = await widget.intelligenceService.processMessage(
      originalText: text,
      preferredLanguage: _preferredLanguage,
    );

    setState(() {
      _messages.add(ChatMessageItem(
        senderId: widget.sessionProvider.localNodeId,
        senderName: widget.sessionProvider.localDisplayName,
        originalText: text,
        processed: processed,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mesh Chat'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate_rounded, color: ResQTheme.meshCyan),
            tooltip: 'Receiver Preferred Language',
            initialValue: _preferredLanguage,
            onSelected: (String lang) {
              setState(() {
                _preferredLanguage = lang;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Target language set to ${lang.toUpperCase()}')),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English (en)')),
              const PopupMenuItem(value: 'te', child: Text('Telugu (తెలుగు)')),
              const PopupMenuItem(value: 'hi', child: Text('Hindi (हिन्दी)')),
              const PopupMenuItem(value: 'ta', child: Text('Tamil (தமிழ்)')),
              const PopupMenuItem(value: 'kn', child: Text('Kannada (ಕನ್ನಡ)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isSelf = msg.senderId == widget.sessionProvider.localNodeId;

                return Align(
                  alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelf ? ResQTheme.surfaceBorder : ResQTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelf ? ResQTheme.meshCyan.withOpacity(0.4) : ResQTheme.surfaceBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: ResQTheme.meshCyan,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lang: ${msg.processed.detectedLanguage.toUpperCase()}',
                              style: const TextStyle(fontSize: 10, color: ResQTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Original Text (Preserved permanently & displayed immediately)
                        Text(
                          msg.originalText,
                          style: const TextStyle(fontSize: 15, color: ResQTheme.textPrimary),
                        ),

                        // Translated Text (if applicable)
                        if (msg.processed.wasTranslated && msg.processed.translatedText != null) ...[
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.g_translate_rounded, size: 14, color: ResQTheme.safeGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Translated to ${_preferredLanguage.toUpperCase()}:',
                                style: const TextStyle(fontSize: 11, color: ResQTheme.safeGreen, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.processed.translatedText!,
                            style: const TextStyle(fontSize: 14, color: ResQTheme.textPrimary),
                          ),
                        ],

                        // Extractive Summary Chip
                        if (msg.processed.wasSummarized && msg.processed.summary != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                msg.isExpanded = !msg.isExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.summarize_rounded, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Extractive Summary (Rule-based):',
                                        style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        msg.isExpanded ? Icons.expand_less : Icons.expand_more,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ],
                                  ),
                                  if (msg.isExpanded) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      msg.processed.summary!,
                                      style: const TextStyle(fontSize: 12, color: ResQTheme.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ResQTheme.surfaceCard,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type emergency message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: ResQTheme.meshCyan),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
