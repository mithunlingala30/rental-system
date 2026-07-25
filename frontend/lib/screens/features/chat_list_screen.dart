import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isVendor = false;
  String _uid = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = await FirebaseService().getCurrentUserProfile();
    if (user != null && mounted) {
      setState(() {
        _isVendor = user.role == 'Vendor';
        _uid = user.id;
      });
      if (!_isVendor &&
          user.location.isNotEmpty &&
          user.location != 'Not set') {
        _searchCtrl.text = user.location;
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _formatChatTime(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) return DateFormat('h:mm a').format(dt);
      if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── WhatsApp-style header ──────────────────────────────────────────
          Container(
            color: const Color(0xFF5C1A1A),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            _isVendor ? 'Inbox' : 'Chats',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.search_rounded,
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
                  if (!_isVendor) ...[
                    // Tabs: Chats / New Chat (find vendors)
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: 'CHATS'),
                        Tab(text: 'FIND VENDORS'),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: _isVendor
                ? _buildVendorInbox()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyChats(),
                      _buildFindVendors(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── My chats (conversations already started) ──────────────────────────────

  Widget _buildMyChats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService().getUserChats(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C1A1A)));
        }
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No chats yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to "Find Vendors" to start a conversation',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(
              height: 1, indent: 76, color: Color(0xFFF0F0F0)),
          itemBuilder: (_, i) {
            final chat = chats[i];
            final participantNames =
                chat['participantNames'] as Map<String, dynamic>? ?? {};
            final participants =
                List<String>.from(chat['participants'] ?? []);
            final partnerId = participants
                .firstWhere((p) => p != _uid, orElse: () => '');
            final partnerName =
                participantNames[partnerId] as String? ?? 'Unknown';
            final lastMessage = chat['lastMessage'] as String? ?? '';
            final timeStr = _formatChatTime(
                chat['lastMessageTime'] as String?);

            return _ChatTile(
              name: partnerName,
              lastMessage: lastMessage,
              time: timeStr,
              isVendor: false,
              onTap: () => context.push('/chat-detail', extra: {
                'partnerId': partnerId,
                'partnerName': partnerName,
              }),
            );
          },
        );
      },
    );
  }

  // ── Find vendors (customer search) ───────────────────────────────────────

  Widget _buildFindVendors() {
    return Column(
      children: [
        // Search bar
        Container(
          color: const Color(0xFFF6F6F6),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: Color(0xFF5C1A1A),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search by city...',
                hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF5C1A1A), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF5C1A1A), size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: FirebaseService().getVendorsByCity(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF5C1A1A)));
              }
              final vendors = snapshot.data ?? [];
              if (vendors.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Enter a city to find vendors'
                            : 'No vendors found in "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 76, color: Color(0xFFF0F0F0)),
                itemBuilder: (_, i) {
                  final v = vendors[i];
                  final name = (v.shopName?.isNotEmpty ?? false)
                      ? v.shopName!
                      : v.name;
                  return _ChatTile(
                    name: name,
                    lastMessage: '${v.location} • ${v.pincode ?? ""}',
                    time: '',
                    isVendor: true,
                    onTap: () => context.push('/chat-detail', extra: {
                      'partnerId': v.id,
                      'partnerName': name,
                    }),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Vendor inbox ──────────────────────────────────────────────────────────

  Widget _buildVendorInbox() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService().getUserChats(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C1A1A)));
        }
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No messages yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer messages will appear here',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(
              height: 1, indent: 76, color: Color(0xFFF0F0F0)),
          itemBuilder: (_, i) {
            final chat = chats[i];
            final participantNames =
                chat['participantNames'] as Map<String, dynamic>? ?? {};
            final participants =
                List<String>.from(chat['participants'] ?? []);
            final partnerId = participants
                .firstWhere((p) => p != _uid, orElse: () => '');
            final partnerName =
                participantNames[partnerId] as String? ?? 'Unknown Customer';
            final lastMessage = chat['lastMessage'] as String? ?? '';
            final timeStr =
                _formatChatTime(chat['lastMessageTime'] as String?);

            return _ChatTile(
              name: partnerName,
              lastMessage: lastMessage,
              time: timeStr,
              isVendor: false,
              onTap: () => context.push('/chat-detail', extra: {
                'partnerId': partnerId,
                'partnerName': partnerName,
              }),
            );
          },
        );
      },
    );
  }
}

// ─── Chat Tile — WhatsApp style ───────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final bool isVendor;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.isVendor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF5C1A1A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (isVendor)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.storefront_rounded,
                              size: 13, color: Color(0xFF5C1A1A)),
                        ),
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ],
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
