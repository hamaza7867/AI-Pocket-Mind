import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Restored
import '../services/supabase_service.dart'; // Restored
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';
import 'login_screen.dart'; // For logout navigation
// import 'setup_screen.dart'; // Removed
import '../utils/theme_utils.dart';
import '../widgets/glass_header.dart'; // Import GlassHeader

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Added Key
  final bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Permissions are handled in individual services now (hardware, context)
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    // Auto-scroll on new message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      key: _scaffoldKey, // Assigned Key
      backgroundColor: FuturisticTheme.getBackgroundColor(
          Provider.of<ThemeProvider>(context).isDarkMode),
      body: Stack(
        children: [
          // 1. Background Gradient/Animation
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: FuturisticTheme.getBackgroundGradient(
                    Provider.of<ThemeProvider>(context).isDarkMode),
              ),
            ),
          ),
          // Neon Glow Effect
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FuturisticTheme.neonPurple.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: FuturisticTheme.neonPurple.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              // 2. Glass Header
              GlassHeader(
                title: 'PocketMind AI',
                onMenuPressed: () {
                  // Open Drawer using Key
                  _scaffoldKey.currentState?.openDrawer();
                },
                actions: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: FuturisticTheme.getAccentColor(
                            Provider.of<ThemeProvider>(context).isDarkMode)),
                    onPressed: () => chatProvider.startNewSession(),
                    tooltip: "New Chat",
                  ),
                ],
              ),

              // 3. Chat List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: 80, // Extra padding for input area
                  ),
                  itemCount: chatProvider.messages.length +
                      (chatProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatProvider.messages.length &&
                        chatProvider.isLoading) {
                      return _buildLoadingIndicator();
                    }
                    final msg = chatProvider.messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              // 4. Input Area (Glassmorphic)
              _buildInputArea(chatProvider),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(chatProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => chatProvider.toggleLiveMode(),
        backgroundColor: chatProvider.isLiveMode
            ? FuturisticTheme.neonRed
            : FuturisticTheme.neonCyan,
        child: Icon(
          chatProvider.isLiveMode ? Icons.stop : Icons.record_voice_over,
          color: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: isUser
            ? FuturisticTheme.neonBorderDecoration.copyWith(
                color: FuturisticTheme.neonCyan.withOpacity(0.1),
                border: Border.all(
                    color: FuturisticTheme.neonCyan.withOpacity(0.4)),
              )
            : FuturisticTheme.getGlassDecoration(isDark).copyWith(
                color: isDark
                    ? const Color(0xFF1E1E24).withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                border: Border.all(
                    color:
                        isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: msg.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: FuturisticTheme.getBodyStyle(isDark),
                code: FuturisticTheme.getMonoStyle(isDark),
                codeblockDecoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
            if (!isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // TTS Button
                  InkWell(
                    onTap: () {
                      Provider.of<ChatProvider>(context, listen: false)
                          .speak(msg.text);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.volume_up,
                          size: 18, color: FuturisticTheme.textGray),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Copy Button
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Copied to clipboard!"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.copy,
                          size: 16, color: FuturisticTheme.textGray),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: FuturisticTheme.getGlassDecoration(isDark),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: FuturisticTheme.neonPurple),
            ),
            const SizedBox(width: 10),
            Text("Thinking...",
                style: FuturisticTheme.getBodyStyle(isDark)
                    .copyWith(color: FuturisticTheme.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatProvider provider) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FuturisticTheme.getSurfaceColor(isDark).withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Image Button
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined,
                color: FuturisticTheme.textGray),
            onPressed: () => provider.attachImage(ImageSource.gallery),
          ),
          IconButton(
            icon:
                const Icon(Icons.attach_file, color: FuturisticTheme.textGray),
            onPressed: () => provider.attachDocument(),
          ),
          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _controller,
                style: FuturisticTheme.getBodyStyle(isDark).copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (val) {
                  provider.sendMessage(val);
                  _controller.clear();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mic / Send
          GestureDetector(
            onLongPress: () => provider.toggleLiveMode(),
            onTap: () {
              if (_controller.text.trim().isEmpty) {
                provider.startListening();
              } else {
                provider.sendMessage(_controller.text);
                _controller.clear();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: FuturisticTheme.neonCyan,
              ),
              child: Icon(
                _controller.text.isEmpty ? Icons.mic : Icons.arrow_upward,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ChatProvider provider) {
    // Access theme
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Drawer(
      backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: FuturisticTheme
                  .primaryGradient, // This is fine, gradients usually work across modes or we can make dynamic too
            ),
            child: Center(
              child: Text(
                'Memory Banks',
                style: FuturisticTheme.getHeaderStyle(isDark)
                    .copyWith(fontSize: 24),
              ),
            ),
          ),

          // User Profile / Context Section
          _buildUserProfileSection(context, provider),

          const Divider(color: Colors.white10),

          // New Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                provider.startNewSession();
                Navigator.pop(context); // Close drawer
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: FuturisticTheme.getNeonBorderDecoration(isDark),
                child: Center(
                  child: Text(
                    '+ New Session',
                    style: FuturisticTheme.getButtonStyle(isDark),
                  ),
                ),
              ),
            ),
          ),

          // Session List
          Expanded(
            child: ListView.builder(
              itemCount: provider.sessions.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final session = provider.sessions[index];
                final sessionId = session['id'] as int;
                final sessionTitle =
                    session['title'] as String? ?? "Session ${index + 1}";
                // final sessionTimestamp = session['timestamp'] as String? ?? ""; // Unused

                final isSelected = sessionId == provider.currentSessionId;

                return ListTile(
                  title: Text(
                    sessionTitle.isEmpty
                        ? 'Session ${index + 1}'
                        : sessionTitle,
                    style: isSelected
                        ? FuturisticTheme.getBodyStyle(isDark)
                            .copyWith(color: FuturisticTheme.neonCyan)
                        : FuturisticTheme.getBodyStyle(isDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatDate(session['created_at']),
                    style: FuturisticTheme.getMonoStyle(isDark).copyWith(
                        fontSize: 10, color: FuturisticTheme.textGray),
                  ),
                  leading: Icon(
                    Icons.chat_bubble_outline,
                    color: isSelected
                        ? FuturisticTheme.neonCyan
                        : FuturisticTheme.textGray,
                  ),
                  onTap: () {
                    provider.loadSession(sessionId);
                    Navigator.pop(context);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[800]),
                    onPressed: () {
                      provider.deleteSession(sessionId);
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white10),
          ListTile(
            leading:
                const Icon(Icons.settings, color: FuturisticTheme.textGray),
            title:
                Text('Settings', style: FuturisticTheme.getBodyStyle(isDark)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: FuturisticTheme.textGray),
            title: Text('About', style: FuturisticTheme.getBodyStyle(isDark)),
            onTap: () {
              // TODO: Show About Dialog
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Logout',
                style: FuturisticTheme.getBodyStyle(isDark)
                    .copyWith(color: Colors.redAccent)),
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
                  title: Text('Logout',
                      style: FuturisticTheme.getHeaderStyle(isDark)),
                  content: Text('Are you sure you want to logout?',
                      style: FuturisticTheme.getBodyStyle(isDark)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && mounted) {
                await SupabaseService().signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "";
    try {
      if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date)
            .toString()
            .substring(0, 16);
      } else if (date is String) {
        // Handle ISO8601 (e.g. 2024-12-31T20:00:00)
        return DateTime.parse(date).toLocal().toString().substring(0, 16);
      }
      return date.toString();
    } catch (e) {
      return "";
    }
  }

  Widget _buildUserProfileSection(BuildContext context, ChatProvider provider) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService().getUserProfile(),
      builder: (context, snapshot) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        final user = snapshot.data;
        final name = user?['full_name'] ?? "Guest User";
        final email = user?['email'] ?? "No Email";

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            collapsedIconColor: FuturisticTheme.textGray,
            iconColor: FuturisticTheme.neonCyan,
            leading: CircleAvatar(
              backgroundColor: FuturisticTheme.neonCyan,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            title: Text(name, style: FuturisticTheme.getBodyStyle(isDark)),
            subtitle: Text(email,
                style:
                    TextStyle(color: FuturisticTheme.textGray, fontSize: 12)),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("User Context (Bio)",
                        style: FuturisticTheme.getMonoStyle(isDark)
                            .copyWith(fontSize: 12)),
                    const SizedBox(height: 5),
                    TextField(
                      controller:
                          TextEditingController(text: provider.systemPrompt),
                      maxLines: 3,
                      style: FuturisticTheme.getBodyStyle(isDark)
                          .copyWith(fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            Provider.of<ThemeProvider>(context).isDarkMode
                                ? Colors.black12
                                : Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: "Tell AI about yourself...",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (val) {
                        provider.updateSettings(
                          desktopBridgeUrl: provider.currentDesktopUrl,
                          apiKey: provider.currentApiKey,
                          mode: provider.currentMode,
                          cloudProvider: provider.currentCloudProvider,
                          cloudModel: provider.currentCloudModel,
                          systemPrompt: val,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Context Updated!")));
                      },
                    ),
                    const SizedBox(height: 5),
                    Text("Press Enter to Save",
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
