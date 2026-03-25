import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/chatbot_service.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/global_loader.dart';
import '../../widgets/floating_bottom_navbar.dart';

class MobileChatbotScreen extends StatefulWidget {
  final int initialNavIndex;
  final Function(int) onNavTap;
  final String? initialPrompt;

  const MobileChatbotScreen({
    super.key,
    required this.initialNavIndex,
    required this.onNavTap,
    this.initialPrompt,
  });

  @override
  State<MobileChatbotScreen> createState() => _MobileChatbotScreenState();
}

class _MobileChatbotScreenState extends State<MobileChatbotScreen> {
  // Scroll
  final ScrollController _scrollController = ScrollController();

  // Input
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _hasText = false;
  File? _stagedFile;

  // STT
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _isListening = false;

  // Conversation state
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _conversationId; // null = new thread, set after first reply
  String? _conversationTitle;
  bool _isBotTyping = false; // shows typing indicator
  List<ConversationSummary> _history = [];
  bool _isLoadingHistory = false;
  bool _isLoadingMessages = false;
  bool _isFirstLoad = true;
  String _sidebarSearchQuery = '';
  final TextEditingController _sidebarSearchController =
      TextEditingController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Hi! I\'m your AI study assistant. Ask me anything about '
          'your schedule, subjects, or study tips.',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      setState(() => _hasText =
          _inputController.text.trim().isNotEmpty || _stagedFile != null);
    });

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _inputController.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage();
      });
    }

    _initSpeech();
    _startInitialLoad();
  }

  Future<void> _startInitialLoad() async {
    await _loadHistory();
    if (mounted) setState(() => _isFirstLoad = false);
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ChatbotService.listConversations();
      if (mounted) setState(() => _history = history);
    } catch (_) {
      // Ignore errors for now or show toast
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _openConversation(ConversationSummary summary) async {
    FocusScope.of(context).unfocus();
    // Close drawer
    Navigator.of(context).pop();

    setState(() {
      _conversationId = summary.id;
      _conversationTitle = summary.title;
      _isLoadingMessages = true;
      _messages.clear();
    });

    try {
      final msgs = await ChatbotService.getMessages(summary.id);
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _messages.clear();
        for (var m in msgs) {
          _messages.add(_ChatMessage(text: m.text, isUser: m.isUser));
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _messages.add(
          _ChatMessage(
            text: 'Could not load messages',
            isUser: false,
            isError: true,
          ),
        );
      });
    }
  }

  void _startNewConversation({bool fromDrawer = true}) {
    FocusScope.of(context).unfocus();
    if (fromDrawer) Navigator.of(context).pop(); // Close drawer
    setState(() {
      _conversationId = null;
      _conversationTitle = null;
      _messages.clear();
      _messages.add(
        _ChatMessage(
          text: 'Hi! I\'m your AI study assistant. Ask me anything about '
              'your schedule, subjects, or study tips.',
          isUser: false,
        ),
      );
    });
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
    setState(() => _sttAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          _inputController.text = result.recognizedWords;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    }
  }

  // ── Send / receive ─────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if ((text.isEmpty && _stagedFile == null) || _isBotTyping) return;

    final fileToSend = _stagedFile;

    // Clear field and optimistically add the user bubble
    _inputController.clear();
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        attachedFilePath: fileToSend?.path,
      ));
      _isBotTyping = true;
      _stagedFile = null;
      _hasText = false;
    });
    _scrollToBottom();

    try {
      final ConverseResult result;
      if (fileToSend != null) {
        result = await ChatbotService.converseWithFile(
          file: fileToSend,
          tool: 'ocr_exam_parser', // dynamic based on file type or context
          message: text,
          conversationId: _conversationId,
        );
      } else {
        result = await ChatbotService.converse(
          message: text,
          conversationId: _conversationId,
        );
      }

      if (!mounted) return;
      setState(() {
        _conversationId = result.conversationId; // persist for next turn
        if (_conversationTitle == null) {
          _conversationTitle = 'Chat ${result.conversationId}';
          // Async update drawer history implicitly:
          _loadHistory();
        }
        _isBotTyping = false;
        _messages.add(_ChatMessage(text: result.response, isUser: false));
      });
    } on ChatbotException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _messages.add(
          _ChatMessage(text: '⚠️ ${e.message}', isUser: false, isError: true),
        );
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final overscrollAllowance = screenHeight * 0.15;

    return PopScope(
      canPop: _conversationId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If we are in a conversation, go back to "new chat" state
        if (_conversationId != null) {
          _startNewConversation(fromDrawer: false);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        backgroundColor: AppTheme.backgroundColor,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Layer 0: Parallax background ──────────────────────────────
            ParallaxBackground(
              scrollController: _scrollController,
              overscrollAllowance: overscrollAllowance,
              screenHeight: screenHeight,
            ),

            // ── Layer 1: Main content or Loading ───────────────────────────
            if (_isFirstLoad)
              const GlobalLoader()
            else
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Message list
                    Expanded(
                      child: _isLoadingMessages
                          ? const GlobalLoader(transparentBg: true)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              // Extra item when bot is typing
                              itemCount:
                                  _messages.length + (_isBotTyping ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (_isBotTyping && i == _messages.length) {
                                  return _buildTypingIndicator();
                                }
                                return _buildBubble(_messages[i]);
                              },
                            ),
                    ),

                    // Input bar
                    _buildInputBar(),
                    // Space for navbar when only greeting is shown
                    SizedBox(height: _messages.length <= 1 ? 110 : 16),
                  ],
                ),
              ),

            // ── Layer 2: Floating navbar ───────────────────────────────────
            if (!_isFirstLoad && _messages.length <= 1)
              FloatingBottomNavbar(
                currentIndex: widget.initialNavIndex,
                onTap: widget.onNavTap,
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          // Side-menu
          _NeumorphicIconButton(
            icon: Image.asset('assets/icons/menu.png', width: 24, height: 24),
            onTap: () {
              FocusScope.of(context).unfocus();
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversationTitle ?? 'AI Assistant',
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_conversationTitle == null)
                  const Text(
                    'Ask me anything',
                    style: TextStyle(
                      color: AppTheme.descriptionTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Extra spacing at top since icon is removed
            const SizedBox(height: 16),

            // ── Scrollable Content ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 12),
                  // ── Core Actions ──
                  _buildSidebarItem(
                    iconWidget: Image.asset('assets/icons/edit.png', width: 22, height: 22),
                    label: 'New chat',
                    isActive: false,
                    onTap: () => _startNewConversation(fromDrawer: true),
                  ),

                  // ── Inline Search Field ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CustomPaint(
                        painter: _InnerShadowPainter(
                          borderRadius: 24,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                            const BoxShadow(
                              color: AppTheme.buttonHighlightColor,
                              offset: Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _sidebarSearchController,
                          onChanged: (val) =>
                              setState(() => _sidebarSearchQuery = val),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search chats...',
                            hintStyle: TextStyle(
                              color: AppTheme.descriptionTextColor.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 13,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/icons/search.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Divider(color: Colors.black12, thickness: 0.5),
                  ),
                  const SizedBox(height: 12),

                  // ── History Header ──
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'HISTORY',
                      style: TextStyle(
                        color: AppTheme.descriptionTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // ── History Content ──
                  ..._buildHistoryContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHistoryContent() {
    if (_isLoadingHistory) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: GlobalLoader(transparentBg: true),
        ),
      ];
    }

    if (_history.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            'No previous chats',
            style: TextStyle(
              color: AppTheme.descriptionTextColor,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }

    final filteredHistory = _history
        .where(
          (c) => c.title.toLowerCase().contains(
                _sidebarSearchQuery.toLowerCase(),
              ),
        )
        .toList();

    if (filteredHistory.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            'No matches found',
            style: TextStyle(
              color: AppTheme.descriptionTextColor,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }

    return filteredHistory.map((thread) {
      final isCurrent = thread.id == _conversationId;
      return _buildSidebarItem(
        iconWidget: Image.asset('assets/icons/message.png', width: 20, height: 20),
        label: thread.title,
        isActive: isCurrent,
        onTap: () => _openConversation(thread),
      );
    }).toList();
  }

  Widget _buildSidebarItem({
    required Widget iconWidget,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    // Increased radius for roundedness
    const double radius = 24.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          painter: isActive
              ? _InnerShadowPainter(
                  borderRadius: radius,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                    const BoxShadow(
                      color: AppTheme.buttonHighlightColor,
                      offset: Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
                )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: isActive
                  ? null
                  : [
                      // Bottom-right shadow (outward elevate)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                      // Top-left highlight (elevation)
                      const BoxShadow(
                        color: AppTheme.buttonHighlightColor,
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          isActive ? AppTheme.primaryColor : AppTheme.textColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Parses text safely preventing <br> replacements from destroying table formatting.
  String _cleanMarkdown(String text) {
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('|')) {
        // Inside a table row: a direct \n replacement would shatter the column struct. Use a space.
        lines[i] = lines[i].replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          ' ',
        );
      } else {
        // Not a table: a structural \n is safe.
        lines[i] = lines[i].replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '\n',
        );
      }
    }
    return lines.join('\n');
  }

  // ── Chat bubble ────────────────────────────────────────────────────────────

  Widget _buildAttachmentPreview(String filePath) {
    final lowerPath = filePath.toLowerCase();
    final isImage = lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png');
    final fileName = filePath.split('\\').last.split('/').last;

    return GestureDetector(
      onTap: () {
        if (isImage) {
          showGeneralDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.9),
            barrierDismissible: true,
            barrierLabel: 'Close Preview',
            pageBuilder: (context, _, __) {
              return Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.file(File(filePath)),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      right: 24,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          OpenFilex.open(filePath);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: isImage ? EdgeInsets.zero : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(filePath),
                  height: 160,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file_rounded,
                      color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            // AI avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  const BoxShadow(
                    color: AppTheme.buttonHighlightColor,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/robot.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                ),
                boxShadow: msg.isUser
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(4, 4),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                        const BoxShadow(
                          color: AppTheme.buttonHighlightColor,
                          offset: Offset(-4, -4),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          offset: const Offset(3, 3),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                        const BoxShadow(
                          color: AppTheme.buttonHighlightColor,
                          offset: Offset(-3, -3),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.attachedFilePath != null)
                    _buildAttachmentPreview(msg.attachedFilePath!),
                  if (msg.text.isNotEmpty)
                    MarkdownBlock(
                      data: _cleanMarkdown(msg.text),
                      config: MarkdownConfig(
                        configs: [
                          PConfig(
                            textStyle: TextStyle(
                              color: msg.isError
                                  ? AppTheme.highlightColor
                                  : msg.isUser
                                      ? AppTheme.primaryColor
                                      : AppTheme.textColor,
                              fontSize: 15,
                              fontWeight: msg.isUser
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.5,
                            ),
                          ),
                          ListConfig(
                            marginLeft: 16,
                            marker: (isOrdered, depth, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 6, top: 4),
                                child: isOrdered
                                    ? Text(
                                        '${index + 1}.',
                                        style: TextStyle(
                                          color: msg.isUser
                                              ? AppTheme.primaryColor
                                              : AppTheme.textColor,
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                      )
                                    : Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: msg.isUser
                                              ? AppTheme.primaryColor
                                              : AppTheme.textColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                              );
                            },
                          ),
                          H1Config(
                            style: TextStyle(
                              color: msg.isUser
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          H2Config(
                            style: TextStyle(
                              color: msg.isUser
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          H3Config(
                            style: TextStyle(
                              color: msg.isUser
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TableConfig(
                            wrapper: (table) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      AppTheme.descriptionTextColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: table,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  const BoxShadow(
                    color: AppTheme.buttonHighlightColor,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/user.png',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Three animated dots shown while waiting for the bot to respond.
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                ),
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-3, -3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/robot.png',
                width: 20,
                height: 20,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  offset: const Offset(3, 3),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: const SpinKitThreeBounce(
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_stagedFile != null) _buildStagedFilePreview(),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: CustomPaint(
              painter: _InnerShadowPainter(
                borderRadius: 28,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    offset: const Offset(4, 4),
                    blurRadius: 3,
                    spreadRadius: -1,
                  ),
                  const BoxShadow(
                    color: AppTheme.buttonHighlightColor,
                    offset: Offset(-4, -4),
                    blurRadius: 3,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ── Plus / attach icon ──────────────────────────────────
                    GestureDetector(
                      onTap: _showAttachOptions,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                        child: Image.asset(
                          'assets/icons/plus.png',
                          width: 26,
                          height: 26,
                        ),
                      ),
                    ),

                    // ── Text field ─────────────────────────────────────────
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocusNode,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ask anything...',
                          hintStyle: TextStyle(
                            color: AppTheme.descriptionTextColor,
                            fontWeight: FontWeight.normal,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),

                    // ── Mic  ↔  Send arrow (AnimatedSwitcher) ─────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: _hasText
                          // ── Send arrow ──────────────────────────────────
                          ? GestureDetector(
                              key: const ValueKey('send'),
                              onTap: _sendMessage,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                                child: Image.asset(
                                  'assets/icons/right_arrow.png',
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                            )
                          // ── Mic ─────────────────────────────────────────
                          : GestureDetector(
                              key: const ValueKey('mic'),
                              onTap: _toggleListening,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Image.asset(
                                    'assets/icons/microphone.png',
                                    key: ValueKey(_isListening),
                                    width: 26,
                                    height: 26,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagedFilePreview() {
    final isImage = _stagedFile!.path.toLowerCase().endsWith('.jpg') ||
        _stagedFile!.path.toLowerCase().endsWith('.jpeg') ||
        _stagedFile!.path.toLowerCase().endsWith('.png');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
            const BoxShadow(
              color: AppTheme.buttonHighlightColor,
              offset: Offset(-2, -2),
              blurRadius: 4,
            ),
          ]),
      child: Row(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_stagedFile!,
                  width: 44, height: 44, fit: BoxFit.cover),
            )
          else
            const Icon(Icons.insert_drive_file_rounded,
                color: AppTheme.primaryColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _stagedFile!.path.split('\\').last.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.descriptionTextColor),
            onPressed: () {
              setState(() {
                _stagedFile = null;
                _hasText = _inputController.text.trim().isNotEmpty;
              });
            },
          )
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _stagedFile = File(pickedFile.path);
        _hasText = true;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _stagedFile = File(result.files.single.path!);
        _hasText = true;
      });
    }
  }

  void _showAttachOptions() {
    // Dismiss keyboard so it doesn't reopen when the sheet is dismissed
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, -6),
              blurRadius: 24,
            ),
            const BoxShadow(
              color: AppTheme.buttonHighlightColor,
              offset: Offset(0, -1),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Neumorphic inset drag handle — same as alert card
            CustomPaint(
              painter: _AttachHandlePainter(),
              child: const SizedBox(width: 56, height: 8),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(
                  icon: Icons.image_rounded,
                  label: 'File',
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument();
                  },
                ),
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Neumorphic inset drag handle painter (mirrors _HandlePainter in neumorphic_alert.dart) ──
class _AttachHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(rRect, Paint()..color = AppTheme.backgroundColor);
    canvas.clipRRect(rRect);

    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(1.5, 1.5),
        blurRadius: 2.0,
      ),
      BoxShadow(
        color: AppTheme.buttonHighlightColor.withValues(alpha: 0.9),
        offset: const Offset(-1.5, -1.5),
        blurRadius: 2.0,
      ),
    ];

    for (final shadow in shadows) {
      final shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);
      final holeRect = rRect.shift(shadow.offset);
      final path = Path()
        ..addRect(rect.inflate(shadow.blurRadius * 5))
        ..addRRect(holeRect);
      canvas.drawPath(path..fillType = PathFillType.evenOdd, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(_AttachHandlePainter _) => false;
}

// ── Data model ─────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final String? attachedFilePath;
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.attachedFilePath,
  });
}

// ── Reusable neumorphic widgets ────────────────────────────────────────────

class _NeumorphicIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _NeumorphicIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(4, 4),
              blurRadius: 8,
              spreadRadius: -1,
            ),
            const BoxShadow(
              color: AppTheme.buttonHighlightColor,
              offset: Offset(-4, -4),
              blurRadius: 8,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: -1,
                ),
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.descriptionTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────

class _InnerShadowPainter extends CustomPainter {
  final double borderRadius;
  final List<BoxShadow> shadows;

  _InnerShadowPainter({required this.borderRadius, required this.shadows});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final boundsPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      );
    canvas.clipPath(boundsPath);

    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);
      final holeRect = rect.shift(shadow.offset).inflate(shadow.spreadRadius);
      final path = Path()..addRect(rect.inflate(shadow.blurRadius * 5));
      path.addRRect(
        RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
      );
      canvas.drawPath(path..fillType = PathFillType.evenOdd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}
