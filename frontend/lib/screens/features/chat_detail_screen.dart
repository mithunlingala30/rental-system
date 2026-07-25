import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';

// ─── WhatsApp-style Chat Detail Screen ────────────────────────────────────────

class ChatDetailScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const ChatDetailScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  String _currentUid = '';
  String _currentName = '';
  String _chatId = '';

  Map<String, dynamic>? _replyTo; // message being replied to
  late AnimationController _replyAnim;
  bool _showEmoji = false;

  // For swipe-to-reply gesture
  double _dragOffset = 0;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _replyAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _initChat();
  }

  Future<void> _initChat() async {
    final user = await FirebaseService().getCurrentUserProfile();
    if (user != null && mounted) {
      setState(() {
        _currentUid = user.id;
        _currentName =
            user.role == 'Vendor' && (user.shopName?.isNotEmpty ?? false)
                ? user.shopName!
                : user.name;
        _chatId = FirebaseService().getChatId(_currentUid, widget.partnerId);
      });
      // Mark all messages as read when opening chat
      if (_chatId.isNotEmpty) {
        FirebaseService().markMessagesRead(_chatId, _currentUid);
      }
    }
  }

  void _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _currentUid.isEmpty) return;

    final reply = _replyTo;
    _ctrl.clear();
    _clearReply();

    await FirebaseService().sendMessage(
      uid1: _currentUid,
      uid2: widget.partnerId,
      text: text,
      senderName: _currentName,
      receiverName: widget.partnerName,
      replyTo: reply,
    );

    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setReply(Map<String, dynamic> msg) {
    setState(() => _replyTo = msg);
    _replyAnim.forward(from: 0);
    _focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() => _replyTo = null);
    _replyAnim.reverse();
  }

  Future<void> _makePhoneCall() async {
    String phone = '';
    if (widget.partnerId.isNotEmpty) {
      final partnerUser = await FirebaseService().getUserById(widget.partnerId);
      if (partnerUser != null && partnerUser.phone.isNotEmpty) {
        phone = partnerUser.phone;
      }
    }

    if (phone.isEmpty) {
      phone = '+15551234567';
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $phone...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _replyAnim.dispose();
    super.dispose();
  }

  // ── Date label helpers ──────────────────────────────────────────────────────

  String _dateSeparatorLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(dt);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Tick widget ─────────────────────────────────────────────────────────────

  Widget _ticks(Map<String, dynamic> msg, bool isMe) {
    if (!isMe) return const SizedBox.shrink();
    final readBy = List<String>.from(msg['readBy'] as List? ?? []);
    final isRead = readBy.contains(widget.partnerId);

    if (isRead) {
      // Blue double tick
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all_rounded, size: 14, color: Colors.blue.shade300),
        ],
      );
    } else {
      // Grey double tick (delivered)
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all_rounded, size: 14, color: Colors.white60),
        ],
      );
    }
  }

  // ── Message bubble ──────────────────────────────────────────────────────────

  Widget _buildBubble(
      Map<String, dynamic> msg, bool isMe, bool isFirst, bool isLast) {
    final text = msg['text'] as String? ?? '';
    final tsStr = msg['timestamp'] as String?;
    String timeStr = '';
    DateTime? dt;
    if (tsStr != null) {
      try {
        dt = DateTime.parse(tsStr).toLocal();
        timeStr = DateFormat('h:mm a').format(dt);
      } catch (_) {}
    }

    final replyTo = msg['replyTo'] as Map<String, dynamic>?;
    final replyText = replyTo?['text'] as String?;
    final replySender =
        replyTo?['senderId'] == _currentUid ? 'You' : widget.partnerName;

    // Bubble colors — sent: app primary, received: white
    const sentBg = Color(0xFF5C1A1A);
    const rcvdBg = Colors.white;

    // Tail shape
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe
          ? const Radius.circular(18)
          : (isLast ? const Radius.circular(4) : const Radius.circular(18)),
      bottomRight: isMe
          ? (isLast ? const Radius.circular(4) : const Radius.circular(18))
          : const Radius.circular(18),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 8 : 2,
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && isLast) ...[
            // Avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF5C1A1A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.partnerName.isNotEmpty
                      ? widget.partnerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ),
          ] else if (!isMe) ...[
            const SizedBox(width: 34),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showMessageOptions(context, msg, isMe);
              },
              onHorizontalDragUpdate: (d) {
                // Swipe right to reply
                if (!isMe && d.delta.dx > 0) {
                  setState(() => _dragOffset = (_dragOffset + d.delta.dx).clamp(0, 60));
                }
                if (isMe && d.delta.dx < 0) {
                  setState(() => _dragOffset = (_dragOffset + d.delta.dx.abs()).clamp(0, 60));
                }
              },
              onHorizontalDragEnd: (_) {
                if (_dragOffset > 40) {
                  _setReply(msg);
                  HapticFeedback.lightImpact();
                }
                setState(() => _dragOffset = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                transform: Matrix4.translationValues(
                  isMe ? -_dragOffset : _dragOffset, 0, 0,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? sentBg : rcvdBg,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply preview
                      if (replyText != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFF0E8E8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: isMe
                                    ? Colors.white54
                                    : const Color(0xFF5C1A1A),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replySender,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isMe
                                      ? Colors.white70
                                      : const Color(0xFF5C1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                replyText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.white60
                                      : const Color(0xFF8B7355),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Message text + time row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                text,
                                style: TextStyle(
                                  color:
                                      isMe ? Colors.white : const Color(0xFF1A1A1A),
                                  fontSize: 14.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isMe
                                        ? Colors.white60
                                        : const Color(0xFF9E9E9E),
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 3),
                                  _ticks(msg, isMe),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, Map<String, dynamic> msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.reply_rounded,
                    color: Color(0xFF5C1A1A)),
                title: const Text('Reply',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _setReply(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded,
                    color: Color(0xFF5C1A1A)),
                title: const Text('Copy',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: msg['text'] as String? ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp chat background
      body: Column(
        children: [
          // ── App bar ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF5C1A1A),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    // Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.partnerName.isNotEmpty
                              ? widget.partnerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.partnerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'online',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.call_rounded,
                          color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Messages list ──────────────────────────────────────────────────
          Expanded(
            child: _chatId.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF5C1A1A)))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseService().getMessages(_chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF5C1A1A)));
                      }

                      final messages = snapshot.data ?? [];

                      // Mark messages read
                      if (_currentUid.isNotEmpty && messages.isNotEmpty) {
                        FirebaseService()
                            .markMessagesRead(_chatId, _currentUid);
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent);
                        }
                      });

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🔒 Messages are end-to-end encrypted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final isMe = msg['senderId'] == _currentUid;

                          // Parse timestamp
                          DateTime? dt;
                          final tsStr = msg['timestamp'] as String?;
                          if (tsStr != null) {
                            try {
                              dt = DateTime.parse(tsStr).toLocal();
                            } catch (_) {}
                          }

                          // Check if we need a date separator
                          bool showDate = false;
                          if (i == 0) {
                            showDate = true;
                          } else {
                            final prevTsStr =
                                messages[i - 1]['timestamp'] as String?;
                            if (prevTsStr != null && dt != null) {
                              try {
                                final prevDt =
                                    DateTime.parse(prevTsStr).toLocal();
                                showDate = !_isSameDay(dt, prevDt);
                              } catch (_) {}
                            }
                          }

                          // Message grouping: is this the last msg from this sender?
                          final isLast = i == messages.length - 1 ||
                              messages[i + 1]['senderId'] != msg['senderId'];
                          final isFirst = i == 0 ||
                              messages[i - 1]['senderId'] != msg['senderId'];

                          return Column(
                            children: [
                              if (showDate && dt != null)
                                _DateSeparator(
                                    label: _dateSeparatorLabel(dt)),
                              _buildBubble(msg, isMe, isFirst, isLast),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),

          // ── Reply preview ──────────────────────────────────────────────────
          if (_replyTo != null)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _replyAnim, curve: Curves.easeOut)),
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      color: const Color(0xFF5C1A1A),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyTo!['senderId'] == _currentUid
                                ? 'You'
                                : widget.partnerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C1A1A),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _replyTo!['text'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8B7355),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _clearReply,
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF8B7355)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Input bar ──────────────────────────────────────────────────────
          Container(
            color: const Color(0xFFF0F0F0),
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 6,
              bottom: MediaQuery.of(context).padding.bottom + 6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Message input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () =>
                              setState(() => _showEmoji = !_showEmoji),
                          icon: Icon(
                            _showEmoji
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focusNode,
                            maxLines: 5,
                            minLines: 1,
                            textCapitalization:
                                TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              hintStyle:
                                  TextStyle(color: Color(0xFF9E9E9E)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 0),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.attach_file_rounded,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Send button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5C1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Separator Widget ────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD1E7DD),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C5F2E),
            ),
          ),
        ),
      ),
    );
  }
}
