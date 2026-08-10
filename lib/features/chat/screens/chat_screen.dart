import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ── Mock data ──────────────────────────────────────────────────────────────────

final _mockMessages = [
  _Msg(
    id: '1',
    isUser: false,
    text:
        'Hi! I\'m your Zindagi AI assistant. I can answer questions about your lab results, medications, and health trends. What would you like to know?',
    time: '9:00 AM',
    sources: [],
  ),
  _Msg(
    id: '2',
    isUser: true,
    text: 'Why is my HbA1c borderline?',
    time: '9:01 AM',
    sources: [],
  ),
  _Msg(
    id: '3',
    isUser: false,
    text:
        'Your HbA1c of 6.8% is slightly above the normal range of <5.7%. This reflects your average blood sugar over the past 3 months. The main contributing factors in your profile are irregular meal timing and low fibre intake.',
    time: '9:01 AM',
    sources: ['July Lab Report', 'Meal Log Analysis'],
  ),
];

const _quickChips = [
  '📊  Explain my blood report',
  '💊  When to take metformin',
  '🥗  Best foods for my condition',
  '📈  My health trend this month',
  '💧  Daily water target for me',
];

class _Msg {
  const _Msg({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
    required this.sources,
  });
  final String id, text, time;
  final bool isUser;
  final List<String> sources;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final List<_Msg> _messages = List.from(_mockMessages);
  bool _isTyping = false;
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMsg = _Msg(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: text.trim(),
      time: _timeNow(),
      sources: [],
    );
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _textCtrl.clear();
    _scrollToBottom();

    // Simulated AI response delay (~1.5 s)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final aiMsg = _Msg(
      id: '${DateTime.now().millisecondsSinceEpoch}ai',
      isUser: false,
      text:
          'Great question! Based on your recent health data and lab results, here\'s what I found: ${text.contains('?') ? 'This is something we can address with small lifestyle changes. I\'ll analyse your full profile to give you a personalised recommendation.' : 'Let me check your health records for a tailored answer.'}',
      time: _timeNow(),
      sources: ['Health Profile', 'AI Analysis'],
    );
    setState(() {
      _isTyping = false;
      _messages.add(aiMsg);
    });
    _scrollToBottom();
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zindagi AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Health Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.primary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  'Profile linked',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Quick chips ──────────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _quickChips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _ChipButton(
                label: _quickChips[i],
                onTap: () => _sendMessage(_quickChips[i]),
              ),
            ),
          ),
          
          const Divider(height: 1),

          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) {
                  return _TypingIndicator(dotCtrl: _dotCtrl);
                }
                return _MessageBubble(
                  msg: _messages[i],
                  isNew: i == _messages.length - 1,
                );
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          _InputBar(
            controller: _textCtrl,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ── Quick chip button (Apple §1: respond on pointer-down) ──────────────────────

class _ChipButton extends StatefulWidget {
  const _ChipButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.94 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.msg, required this.isNew});
  final _Msg msg;
  final bool isNew;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    if (widget.isNew) {
      // Apple §7: bubble enters from the bottom (its natural origin)
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)
            .value
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: widget.msg.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.msg.isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.msg.isUser ? 20 : 4),
                  bottomRight: Radius.circular(widget.msg.isUser ? 4 : 20),
                ),
                border: widget.msg.isUser
                    ? null
                    : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                widget.msg.text,
                style: TextStyle(
                  fontSize: 15,
                  color: widget.msg.isUser
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Sources + time
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.msg.sources.isNotEmpty) ...[
                  ...widget.msg.sources.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                Text(
                  widget.msg.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator ───────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.dotCtrl});
  final AnimationController dotCtrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: AnimatedBuilder(
              animation: dotCtrl,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i / 3;
                  final v = mathSin(
                    (dotCtrl.value - delay).clamp(0.0, 1.0) * 3.14,
                  );
                  return Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.3 + v * 0.5),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double mathSin(double x) {
    if (x <= 0 || x >= 1) return 0;
    return 4 * x * (1 - x);
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final Future<void> Function(String) onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
      () => setState(() => _hasText = widget.controller.text.isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: widget.controller,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                ),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask about your health…',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  filled: false,
                ),
                onSubmitted: widget.onSend,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button — Apple §1: respond on pointer-down
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onSend(widget.controller.text);
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: _pressed ? 0.88 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hasText ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: _hasText
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
