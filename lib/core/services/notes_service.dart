import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudyNote {
  final int id;
  /// The broad subject this note belongs to (e.g. "Operating Systems")
  final String parentTopic;
  /// The specific note/chapter title (e.g. "Process Management")
  final String topicTitle;
  final DateTime createdAt;

  StudyNote({
    required this.id,
    required this.parentTopic,
    required this.topicTitle,
    required this.createdAt,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'] as int,
      parentTopic: (json['parent_topic'] as String? ?? '').trim().isNotEmpty
          ? json['parent_topic'] as String
          : (json['topic_title'] as String? ?? 'General'),
      topicTitle: json['topic_title'] as String? ?? 'Untitled Note',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NotesService {
  static const String _baseUrl = 'https://prominder.up.railway.app';

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<StudyNote>> getNotes() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl/api/chatbot/notes/');

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StudyNote.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load notes. Status ${response.statusCode}');
    }
  }
}
