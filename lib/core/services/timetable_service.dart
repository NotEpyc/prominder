import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Topic {
  final int id;
  final String name;
  final int estimatedMinutes;
  final int priority;
  final int completedMinutes;

  const Topic({
    required this.id,
    required this.name,
    required this.estimatedMinutes,
    required this.priority,
    required this.completedMinutes,
  });

  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
    id: j['id'] as int,
    name: j['name'] as String? ?? 'Unnamed',
    estimatedMinutes: j['estimated_minutes'] as int? ?? 0,
    priority: j['priority'] as int? ?? 0,
    completedMinutes: j['completed_minutes'] as int? ?? 0,
  );
}

class TimetableEntry {
  final int id;
  final Topic topic;
  final DateTime start;
  final DateTime end;
  final bool notified;
  final bool done;

  const TimetableEntry({
    required this.id,
    required this.topic,
    required this.start,
    required this.end,
    required this.notified,
    required this.done,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
    id: j['id'] as int,
    topic: Topic.fromJson(j['topic'] as Map<String, dynamic>),
    start: DateTime.parse(j['start'] as String).toLocal(),
    end: DateTime.parse(j['end'] as String).toLocal(),
    notified: j['notified'] as bool? ?? false,
    done: j['done'] as bool? ?? false,
  );
}

class TimetableService {
  static const Duration _timeout = Duration(seconds: 40);

  static String get _baseUrl => 'https://prominder.up.railway.app';

  /// Call this after any chatbot tool creates/modifies timetable entries so
  /// the next [fetchEntries] call hits the network instead of stale cache.
  static Future<void> invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_timetable_entries');
    await prefs.remove('timetable_fetched_at');
  }

  static Future<Map<String, String>> _authHeaders([
    String? overrideToken,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = overrideToken ?? prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Exception _mapError(Object e) {
    if (e is TimeoutException) {
      return Exception(
        'The server took too long to respond. Please try again.',
      );
    }
    if (e is SocketException) {
      return Exception(
        'Could not reach the server. Check your internet connection.',
      );
    }
    return Exception(e.toString());
  }

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
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
    } else {
      response = await http.get(uri, headers: headers).timeout(_timeout);
    }

    if (response.statusCode != 401) {
      return response;
    }

    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }

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

        headers = await _authHeaders(newAccessToken);
        if (method == 'POST') {
          return await http
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
        } else {
          return await http.get(uri, headers: headers).timeout(_timeout);
        }
      }
    }
    throw Exception('Session expired. Please log in again.');
  }

  static Future<List<TimetableEntry>> fetchEntries({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedStr = prefs.getString('cached_timetable_entries');
      final fetchedAtStr = prefs.getString('timetable_fetched_at');
      if (cachedStr != null && fetchedAtStr != null) {
        final fetchedAt = DateTime.tryParse(fetchedAtStr);
        // Cache valid for 2 hours
        if (fetchedAt != null &&
            DateTime.now().difference(fetchedAt) < const Duration(hours: 2)) {
          try {
            final list = jsonDecode(cachedStr) as List<dynamic>;
            return list
                .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }
      }
    }

    try {
      final response = await _sendAuthenticatedRequest(
        'GET',
        '/api/timetable/entries/',
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.body;
        final list = jsonDecode(jsonResponse) as List<dynamic>;
        final typedList =
            list
                .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
                .toList();

        await prefs.setString('cached_timetable_entries', jsonResponse);
        await prefs.setString(
          'timetable_fetched_at',
          DateTime.now().toIso8601String(),
        );

        return typedList;
      }
      throw Exception('Failed to load timetable (${response.statusCode})');
    } catch (e) {
      // Offline fallback
      final cachedStr = prefs.getString('cached_timetable_entries');
      if (cachedStr != null && !forceRefresh) {
        try {
          final list = jsonDecode(cachedStr) as List<dynamic>;
          return list
              .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      throw _mapError(e);
    }
  }
}
