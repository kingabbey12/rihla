import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_chat_bubble.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_composer.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_voice_overlay.dart';

class _Turn {
  _Turn({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.streaming = false,
    this.typing = false,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  bool streaming;
  bool typing;
}

/// Modern AI conversation screen — chat bubbles, streaming text, typing
/// indicator, markdown, and a glass composer. Conversational replies are a
/// presentation layer over the existing AI copilot experience.
class AiConversationPage extends ConsumerStatefulWidget {
  const AiConversationPage({
    super.key,
    this.initialPrompt,
    this.startVoice = false,
  });

  final String? initialPrompt;
  final bool startVoice;

  @override
  ConsumerState<AiConversationPage> createState() => _AiConversationPageState();
}

class _AiConversationPageState extends ConsumerState<AiConversationPage> {
  final _scroll = ScrollController();
  final List<_Turn> _turns = [];
  Timer? _replyTimer;
  Timer? _voiceTimer;
  AiVoicePhase? _voicePhase;

  @override
  void initState() {
    super.initState();
    _turns.add(_Turn(
      text: "Hi, I'm your Rihla copilot. I can help you plan journeys, "
          'avoid traffic, find fuel or coffee, and stay safe on the road. '
          'How can I help you today?',
      isUser: false,
      timestamp: DateTime.now(),
      streaming: true,
    ));
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(widget.initialPrompt!);
      });
    }
    if (widget.startVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startVoice());
    }
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _voiceTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String text) {
    setState(() {
      _turns.add(_Turn(text: text, isUser: true, timestamp: DateTime.now()));
      _turns.add(_Turn(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        typing: true,
      ));
    });
    _scrollToBottom();

    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final reply = _replyFor(text);
      setState(() {
        _turns.removeWhere((t) => t.typing);
        _turns.add(_Turn(
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
          streaming: true,
        ));
      });
      _scrollToBottom();
    });
  }

  void _startVoice() {
    setState(() => _voicePhase = AiVoicePhase.listening);
    _voiceTimer?.cancel();
    _voiceTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _voicePhase = AiVoicePhase.thinking);
      _voiceTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() => _voicePhase = null);
        _send('Find the fastest route home');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = ref.watch(aiIsLiveProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const AiGradientOrb(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rihla AI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                Text(
                  isLive ? 'Online · live model' : 'Online · ready',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: _turns.length,
                  itemBuilder: (context, i) {
                    final turn = _turns[i];
                    final prev = i > 0 ? _turns[i - 1] : null;
                    final grouped = prev != null && prev.isUser == turn.isUser;
                    return AiChatBubble(
                      text: turn.text,
                      isUser: turn.isUser,
                      timestamp: turn.timestamp,
                      showAvatar: !grouped,
                      streaming: turn.streaming,
                      typing: turn.typing,
                      onStreamComplete: () {
                        turn.streaming = false;
                        _scrollToBottom();
                      },
                    );
                  },
                ),
              ),
              AiComposer(
                onSend: _send,
                onMic: _startVoice,
              ),
            ],
          ),
          if (_voicePhase != null)
            AiVoiceOverlay(
              phase: _voicePhase!,
              transcript: _voicePhase == AiVoicePhase.listening
                  ? '"Find the fastest route home"'
                  : null,
              onClose: () {
                _voiceTimer?.cancel();
                setState(() => _voicePhase = null);
              },
            ),
        ],
      ),
    );
  }

  /// Warm, concise, on-brand replies mapped to intent. Presentation-only.
  String _replyFor(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('traffic') || p.contains('avoid')) {
      return '**Traffic is moderate** on your usual routes right now.\n\n'
          '- Sheikh Zayed Rd — about **8 min** of delay near the interchange\n'
          '- Al Khail Rd — flowing well, a smoother alternative\n\n'
          'I can reroute you via Al Khail to save roughly 6 minutes. '
          'Want me to update your route?';
    }
    if (p.contains('fuel') || p.contains('petrol') || p.contains('gas') ||
        p.contains('charge') || p.contains('ev')) {
      return 'Here are the **closest options** along your direction of travel:\n\n'
          '- **ENOC — Jumeirah** · 1.2 km · open now\n'
          '- **ADNOC — Al Wasl** · 2.0 km · open now\n\n'
          'Both are a short detour. Shall I navigate to ENOC?';
    }
    if (p.contains('coffee') || p.contains('cafe') || p.contains('eat') ||
        p.contains('restaurant') || p.contains('food')) {
      return 'A coffee break sounds good. Nearby and well-rated:\n\n'
          '- **% Arabica** · 0.8 km · ★ 4.8\n'
          '- **Common Grounds** · 1.5 km · ★ 4.6\n\n'
          'Want directions to % Arabica?';
    }
    if (p.contains('emergency') || p.contains('help') || p.contains('sos') ||
        p.contains('accident')) {
      return 'Stay calm — I\'m here to help. If this is urgent:\n\n'
          '- Tap **SOS** to alert emergency services and your contacts\n'
          '- Pull over safely if you can\n\n'
          'I can also share your live location. Would you like me to?';
    }
    if (p.contains('weather') || p.contains('rain')) {
      return 'The weather ahead looks **clear** with good visibility. '
          'No rain expected on your route in the next hour — a great time to drive.';
    }
    if (p.contains('route') || p.contains('home') || p.contains('plan') ||
        p.contains('journey') || p.contains('drive') || p.contains('go')) {
      return 'I\'ve put together a plan:\n\n'
          '## Recommended departure\n'
          'Leave within the next **15 minutes** to beat the build-up.\n\n'
          '## Best route\n'
          '- Estimated **24 min** · 18.5 km\n'
          '- Safety score **88/100** · light traffic\n\n'
          'Ready when you are — just say the word and I\'ll start navigation.';
    }
    return 'Got it. Here\'s how I can help:\n\n'
        '- Plan the smoothest journey and departure time\n'
        '- Avoid traffic and find fuel, charging, or coffee\n'
        '- Keep an eye on safety and the weather ahead\n\n'
        'What would you like to do first?';
  }
}
