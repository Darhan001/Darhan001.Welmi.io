import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/l10n/app_localizations.dart';

// ─── Premium design tokens ────────────────────────────────────
class _Design {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color lime = Color(0xFFD4FF44);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF555555);
  static const double radiusLg = 28;
  static const double radiusMd = 20;
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AiService _aiService = AiService();

  final List<_ChatBubble> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    await _aiService.loadChatHistory();
    if (!mounted) return;

    final saved = _aiService.chatHistory;
    if (saved.isNotEmpty) {
      setState(() {
        _messages.addAll(
          saved.map((m) => _ChatBubble(
            text: m.text,
            isUser: m.role == 'user',
            timestamp: m.timestamp,
          )),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage({String? text}) async {
    final message = text ?? _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();
    if (text == null) _messageController.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(_ChatBubble(text: message, isUser: true));
      _isLoading = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      final response = await _aiService.sendChatMessage(message);
      if (mounted) {
        setState(() {
          _messages.add(_ChatBubble(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatBubble(
            text: '❌ **Ошибка соединения**\n\n${AppLocalizations.of(context)!.aiErrorConnection}',
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _startNewChat() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Design.radiusLg)),
        backgroundColor: _Design.card,         title: Text(AppLocalizations.of(context)!.aiNewChat,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: _Design.textPrimary)),         content: Text(AppLocalizations.of(context)!.aiNewChatConfirm,
            style: GoogleFonts.inter(color: _Design.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),             child: Text(AppLocalizations.of(context)!.drawerCancel,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _Design.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _isLoading = false;
                _errorMessage = null;
              });
              _aiService.startNewChat();
            },             child: Text(AppLocalizations.of(context)!.aiStart,
                style: GoogleFonts.inter(
                    color: _Design.lime, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: _Design.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Back button bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: _Design.textPrimary, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasMessages ? _buildChatView() : _buildWelcomeView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Welcome View (no messages yet) ────────────────────────
  Widget _buildWelcomeView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Glow avatar
                  _buildGlowAvatar(),
                  const SizedBox(height: 24),
                  // Capsule label
                  Text(                     AppLocalizations.of(context)!.gymtoneTrainer,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: _Design.lime.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Greeting
                  Text(                     AppLocalizations.of(context)!.aiWelcomeGreeting,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _Design.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Suggestion pills                   _buildSuggestion(AppLocalizations.of(context)!.aiSuggestion1),
                  const SizedBox(height: 10),                   _buildSuggestion(AppLocalizations.of(context)!.aiSuggestion2),
                  const SizedBox(height: 10),                   _buildSuggestion(AppLocalizations.of(context)!.aiSuggestion3),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // Input field
        _buildInputArea(),
      ],
    );
  }

  // ─── Chat View (has messages) ──────────────────────────────
  Widget _buildChatView() {
    return Column(
      children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),
        // Error message (if any)
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(_Design.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        // Input field
        _buildInputArea(),
      ],
    );
  }

  // ─── Glow Avatar ───────────────────────────────────────────
  Widget _buildGlowAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _Design.lime.withValues(alpha: 0.2),
            _Design.lime.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _Design.lime.withValues(alpha: 0.1),
            border: Border.all(color: _Design.lime.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _Design.lime.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'W',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Suggestion Pill ───────────────────────────────────────
  Widget _buildSuggestion(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text: text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _Design.card,
              const Color(0xFF222222),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_Design.radiusLg),
          border: Border.all(color: _Design.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _Design.textPrimary,
          ),
        ),
      ),
    );
  }

  // ─── Message Bubble ────────────────────────────────────────
  Widget _buildMessageBubble(_ChatBubble message) {
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? _Design.lime.withValues(alpha: 0.12)
        : _Design.card;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: isUser
                      ? _Design.lime.withValues(alpha: 0.1)
                      : _Design.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageText(message.text, isUser),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _Design.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: 12, color: _Design.lime.withValues(alpha: 0.5)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isUser) {
    final textColor = isUser ? _Design.lime : _Design.textPrimary;

    final theme = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: textColor,
      fontWeight: FontWeight.w500,
    );

    return text.contains('**') || text.contains('_')
        ? RichText(
            text: _parseFormattedText(text, isUser),
            textScaler: MediaQuery.textScalerOf(context),
          )
        : Text(
            text,
            style: theme.copyWith(
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
          );
  }

  TextSpan _parseFormattedText(String text, bool isUser) {
    final baseColor = isUser ? _Design.lime : _Design.textPrimary;
    final italicColor = isUser
        ? _Design.lime.withValues(alpha: 0.7)
        : _Design.textSecondary;

    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*(.+?)\*\*|_(.+?)_)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: baseColor,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      if (match.group(1)?.startsWith('**') == true) {
        spans.add(TextSpan(
          text: match.group(2),
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: baseColor,
            fontWeight: FontWeight.w800,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: match.group(3),
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: italicColor,
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          color: baseColor,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    return TextSpan(children: spans);
  }

  // ─── Typing Indicator ──────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: 48, top: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _Design.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _Design.cardBorder),
            ),
            child: _TypingDots(dotColor: _Design.lime),
          ),
        ],
      ),
    );
  }

  // ─── Input Area ────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: _Design.bg,
        border: Border(
          top: BorderSide(color: _Design.cardBorder.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: _Design.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _Design.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 4),
              // New chat button
              GestureDetector(
                onTap: _startNewChat,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: 20,
                    color: _Design.lime.withValues(alpha: 0.6),
                  ),
                ),
              ),
              // Text field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isLoading,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _Design.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: _isLoading ? AppLocalizations.of(context)!.aiHintLoading : AppLocalizations.of(context)!.aiHintInput,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _Design.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  ),
                ),
              ),
              // Send button
              GestureDetector(
                onTap: _isLoading ? null : () => _sendMessage(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? _Design.textMuted.withValues(alpha: 0.3)
                        : _Design.lime,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.arrow_upward_rounded,
                    color: _isLoading ? _Design.textMuted : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.aiJustNow;
    if (diff.inMinutes < 60) return AppLocalizations.of(context)!.aiMinutesAgo(diff.inMinutes);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatBubble({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Animated typing dots
class _TypingDots extends StatefulWidget {
  final Color dotColor;

  const _TypingDots({this.dotColor = Colors.white});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dot(0.0),
              _dot(0.2),
              _dot(0.4),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(double delay) {
    final phase = (_controller.value - delay) * pi;
    final offset = -8 * sin(phase).clamp(-1.0, 1.0);
    return Transform.translate(
      offset: Offset(0, offset > 0 ? 0 : offset),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.dotColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
