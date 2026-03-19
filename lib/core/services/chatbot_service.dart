import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

class ConverseResult {
  final String response;
  final String? tool;
  final bool contextUsed;
  final int conversationId;

  const ConverseResult({
    required this.response,
    this.tool,
    required this.contextUsed,
    required this.conversationId,
  });

  factory ConverseResult.fromJson(Map<String, dynamic> j) => ConverseResult(
        response: j['response'] as String? ?? '',
        tool: j['tool'] as String?,
        contextUsed: j['context_used'] as bool? ?? false,
        conversationId: j['conversation_id'] as int,
      );
}

class ConversationSummary {
  final int id;
  final String title;
  final String startedAt;
  final int messageCount;

  const ConversationSummary({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.messageCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j) =>
      ConversationSummary(
        id: j['id'] as int,
        title: j['title'] as String? ?? 'New Chat',
        startedAt: j['started_at'] as String? ?? '',
        messageCount: j['message_count'] as int? ?? 0,
      );
}

class ConversationMessage {
  final int id;
  final int conversationId;
  final String sender; // 'user' | 'bot'
  final String text;
  final String timestamp;

  const ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => sender == 'user';

  factory ConversationMessage.fromJson(Map<String, dynamic> j) =>
      ConversationMessage(
        id: j['id'] as int,
        conversationId: j['conversation'] as int,
        sender: j['sender'] as String? ?? 'bot',
        text: j['text'] as String? ?? '',
        timestamp: j['timestamp'] as String? ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotException implements Exception {
  final String message;
  final int? statusCode;
  const ChatbotException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotService {
  static const Duration _timeout = Duration(seconds: 30);

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String get _baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw ChatbotException('API_BASE_URL is not set in .env');
    }
    return url;
  }

  // ── IN-MEMORY CACHE ────────────────────────────────────────────────────────
  static List<ConversationSummary>? _cachedHistory;
  static DateTime? _historyLastFetched;
  
  static final Map<int, List<ConversationMessage>> _cachedMessages = {};
  static final Map<int, DateTime> _messagesLastFetched = {};
  
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<Map<String, String>> _authHeaders([String? overrideToken]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = overrideToken ?? prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static ChatbotException _mapError(Object e) {
    if (e is ChatbotException) return e;
    if (e is TimeoutException) {
      return const ChatbotException(
        'The server took too long to respond. Please try again.',
      );
    }
    if (e is SocketException) {
      return const ChatbotException(
        'Could not reach the server. Check your internet connection.',
      );
    }
    return ChatbotException('Something went wrong: ${e.toString()}');
  }

  /// Wrapper for HTTP requests that automatically handles JWT token refresh on 401.
  static Future<http.Response> _sendAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    var headers = await _authHeaders();

    http.Response response;
    if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
    } else {
      response = await http.get(uri, headers: headers).timeout(_timeout);
    }

    // If perfectly fine, return immediately
    if (response.statusCode != 401) {
      return response;
    }

    // Got a 401 Unauthorized — attempt to refresh the token
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ChatbotException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    // Call token refresh
    final refreshResponse = await http
        .post(
          Uri.parse('$_baseUrl/api/auth/token/refresh/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        )
        .timeout(_timeout);

    if (refreshResponse.statusCode == 200) {
      final data = jsonDecode(refreshResponse.body);
      final newAccessToken = data['access'];
      if (newAccessToken != null) {
        await prefs.setString('access_token', newAccessToken);
        if (data['refresh'] != null) {
          await prefs.setString('refresh_token', data['refresh']);
        }

        // Retry original request with new token
        headers = await _authHeaders(newAccessToken);
        if (method == 'POST') {
          return await http
              .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(_timeout);
        } else {
          return await http.get(uri, headers: headers).timeout(_timeout);
        }
      }
    }

    // If refresh failed (e.g., refresh token expired)
    throw const ChatbotException(
      'Session expired. Please log in again.',
      statusCode: 401,
    );
  }

  // ── POST /api/chatbot/converse/ ───────────────────────────────────────────

  /// Sends [message] to the AI. Pass [conversationId] to continue an existing
  /// thread; omit (null) to start a new one.
  static Future<ConverseResult> converse({
    required String message,
    int? conversationId,
  }) async {
    try {
      final body = <String, dynamic>{'message': message};
      if (conversationId != null) body['conversation_id'] = conversationId;

      // Un-cache preemptively since state is aggressively changing.
      _cachedHistory = null;
      if (conversationId != null) {
        _cachedMessages.remove(conversationId);
        _messagesLastFetched.remove(conversationId);
      }

      final response = await _sendAuthenticatedRequest(
        'POST',
        '/api/chatbot/converse/',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ConverseResult.fromJson(data);
      }

      // Surface API-level error messages when available
      String errorMsg = 'Server error (${response.statusCode})';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (err['error'] != null) errorMsg = err['error'] as String;
        if (err['detail'] != null) errorMsg = err['detail'] as String;
      } catch (_) {}
      throw ChatbotException(errorMsg, statusCode: response.statusCode);
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ── GET /api/chatbot/conversations/ ──────────────────────────────────────

  static Future<List<ConversationSummary>> listConversations() async {
    // Return cached list if valid and within TTL buffer.
    if (_cachedHistory != null &&
        _historyLastFetched != null &&
        DateTime.now().difference(_historyLastFetched!) < _cacheDuration) {
      return _cachedHistory!;
    }

    try {
      final response = await _sendAuthenticatedRequest(
        'GET',
        '/api/chatbot/conversations/',
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final typedList = list
            .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
            .toList();
            
        // Save to cache
        _cachedHistory = typedList;
        _historyLastFetched = DateTime.now();
        
        return typedList;
      }
      throw ChatbotException(
        'Failed to load conversations (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  // ── GET /api/chatbot/conversations/<id>/messages/ ─────────────────────────

  static Future<List<ConversationMessage>> getMessages(
      int conversationId) async {
    // Return cached messages if exactly fresh valid within TTL buffer.
    if (_cachedMessages.containsKey(conversationId) &&
        _messagesLastFetched.containsKey(conversationId) &&
        DateTime.now().difference(_messagesLastFetched[conversationId]!) < _cacheDuration) {
      return _cachedMessages[conversationId]!;
    }

    try {
      final response = await _sendAuthenticatedRequest(
        'GET',
        '/api/chatbot/conversations/$conversationId/messages/',
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final typedList = list
            .map((e) =>
                ConversationMessage.fromJson(e as Map<String, dynamic>))
            .toList();
            
        // Save to specific chat cache
        _cachedMessages[conversationId] = typedList;
        _messagesLastFetched[conversationId] = DateTime.now();
        
        return typedList;
      }
      throw ChatbotException(
        'Failed to load messages (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }
}
