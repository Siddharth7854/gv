import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/gov_theme.dart';
import '../../providers/admin_providers_fix.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Load chat data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminChatProvider.notifier).fetchChatConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredConversations(
    List<Map<String, dynamic>> conversations,
  ) {
    var filtered = conversations;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conv) {
        final grievanceTitle =
            conv['grievance_title']?.toString().toLowerCase() ?? '';
        final userName = conv['user_name']?.toString().toLowerCase() ?? '';
        final grievanceId =
            conv['grievance_id']?.toString().toLowerCase() ?? '';

        return grievanceTitle.contains(_searchQuery.toLowerCase()) ||
            userName.contains(_searchQuery.toLowerCase()) ||
            grievanceId.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((conv) {
        switch (_selectedFilter) {
          case 'Unread':
            return conv['unread_count'] != null && conv['unread_count'] > 0;
          case 'Active':
            return conv['status']?.toString().toLowerCase() == 'active';
          case 'Resolved':
            return conv['status']?.toString().toLowerCase() == 'resolved';
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header Actions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: GovTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Chat Management',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GovTheme.darkGray,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: GovTheme.primaryBlue),
                  onPressed: () {
                    ref
                        .read(adminChatProvider.notifier)
                        .fetchChatConversations();
                  },
                  tooltip: 'Refresh Chats',
                ),
              ],
            ),
          ),

          // Search and Filter Bar
          _buildSearchAndFilterBar(),

          // Stats Cards
          _buildChatStatsCards(),

          // Chat List
          Expanded(child: _buildChatList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search conversations by user, grievance ID, or title...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  items: ['All', 'Unread', 'Active', 'Resolved'].map((filter) {
                    return DropdownMenuItem(value: filter, child: Text(filter));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatStatsCards() {
    final chatState = ref.watch(adminChatProvider);
    final conversations = chatState.conversations;

    // Calculate stats
    final totalChats = conversations.length;
    final unreadChats = conversations
        .where((c) => c['unread_count'] != null && c['unread_count'] > 0)
        .length;
    final activeChats = conversations
        .where((c) => c['status']?.toString().toLowerCase() == 'active')
        .length;
    final resolvedChats = conversations
        .where((c) => c['status']?.toString().toLowerCase() == 'resolved')
        .length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            // Mobile: 2x2 grid
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Chats',
                        totalChats.toString(),
                        Icons.chat,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Unread',
                        unreadChats.toString(),
                        Icons.mark_chat_unread,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active',
                        activeChats.toString(),
                        Icons.chat_bubble,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Resolved',
                        resolvedChats.toString(),
                        Icons.check_circle,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop: Single row
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Chats',
                    totalChats.toString(),
                    Icons.chat,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Unread',
                    unreadChats.toString(),
                    Icons.mark_chat_unread,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    activeChats.toString(),
                    Icons.chat_bubble,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Resolved',
                    resolvedChats.toString(),
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                count,
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final chatState = ref.watch(adminChatProvider);

    if (chatState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chat conversations...'),
          ],
        ),
      );
    }

    if (chatState.error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error loading chats',
                style: GoogleFonts.roboto(fontSize: 18, color: Colors.red[600]),
              ),
              const SizedBox(height: 8),
              Text(
                chatState.error!,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(adminChatProvider.notifier).fetchChatConversations();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final conversations = _getFilteredConversations(chatState.conversations);

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedFilter == 'All'
                  ? 'No chat conversations found'
                  : 'No conversations match your search',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filter criteria',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final unreadCount = conversation['unread_count'] ?? 0;
    final isUnread = unreadCount > 0;
    final lastMessage = conversation['last_message'] ?? '';
    final lastMessageTime = conversation['last_message_time'] ?? '';
    final userName = conversation['user_name'] ?? 'Unknown User';
    final grievanceId = conversation['grievance_id'] ?? 'N/A';
    final grievanceTitle = conversation['grievance_title'] ?? 'No Title';
    final status = conversation['status']?.toString().toLowerCase() ?? 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isUnread
              ? GovTheme.primaryBlue.withValues(alpha: 0.3)
              : Colors.transparent,
          width: isUnread ? 1 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openChatConversation(conversation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // User Avatar
                  CircleAvatar(
                    backgroundColor: GovTheme.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    radius: 20,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.roboto(
                        color: GovTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // User and Grievance Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Grievance: $grievanceId',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Grievance Title
              Text(
                grievanceTitle,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: GovTheme.darkGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Last Message
              if (lastMessage.isNotEmpty) ...[
                Text(
                  lastMessage,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Bottom Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(lastMessageTime),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openChatConversation(conversation),
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Open Chat'),
                        style: TextButton.styleFrom(
                          foregroundColor: GovTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _markAsRead(conversation['id']),
                          icon: const Icon(Icons.mark_chat_read, size: 16),
                          label: const Text('Mark Read'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'resolved':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return 'Unknown';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timeStr;
    }
  }

  void _openChatConversation(Map<String, dynamic> conversation) {
    // Navigate to detailed chat conversation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatConversationScreen(
          conversationId: conversation['id'],
          grievanceId: conversation['grievance_id'],
          userName: conversation['user_name'] ?? 'Unknown User',
          grievanceTitle: conversation['grievance_title'] ?? 'No Title',
        ),
      ),
    );
  }

  void _markAsRead(String conversationId) {
    ref.read(adminChatProvider.notifier).markConversationAsRead(conversationId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation marked as read'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Chat Conversation Detail Screen
class AdminChatConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String grievanceId;
  final String userName;
  final String grievanceTitle;

  const AdminChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.grievanceId,
    required this.userName,
    required this.grievanceTitle,
  });

  @override
  ConsumerState<AdminChatConversationScreen> createState() =>
      _AdminChatConversationScreenState();
}

class _AdminChatConversationScreenState
    extends ConsumerState<AdminChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load chat messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminChatProvider.notifier)
          .fetchChatMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(adminChatProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GovTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Grievance: ${widget.grievanceId}',
              style: GoogleFonts.roboto(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGrievanceInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Grievance Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: GovTheme.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              widget.grievanceTitle,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: GovTheme.darkGray,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Chat Messages
          Expanded(child: _buildChatMessages()),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    final chatState = ref.watch(adminChatProvider);

    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final messages = chatState.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isAdmin = message['sender_type'] == 'admin';

        return Align(
          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isAdmin ? GovTheme.primaryBlue : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['message'] ?? '',
                  style: GoogleFonts.roboto(
                    color: isAdmin ? Colors.white : GovTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message['created_at']),
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: isAdmin ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: GovTheme.primaryBlue,
            mini: true,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final time = DateTime.parse(timeStr);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    ref
        .read(adminChatProvider.notifier)
        .sendMessage(widget.conversationId, widget.grievanceId, message);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showGrievanceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grievance Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${widget.grievanceId}'),
            const SizedBox(height: 8),
            Text('Title: ${widget.grievanceTitle}'),
            const SizedBox(height: 8),
            Text('User: ${widget.userName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
