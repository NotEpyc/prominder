import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }
}

class AuthService {
  static const Duration _timeout = Duration(seconds: 40);

  static String get _baseUrl => 'https://prominder.up.railway.app';

  static Future<Map<String, String>> _authHeaders([String? overrideToken]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = overrideToken ?? prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<UserProfile> fetchProfile({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedJson = prefs.getString('cached_profile');
      final fetchedStr = prefs.getString('profile_fetched_at');
      if (cachedJson != null && fetchedStr != null) {
        final fetchedAt = DateTime.tryParse(fetchedStr);
        // Cache valid for 2 hours
        if (fetchedAt != null && DateTime.now().difference(fetchedAt) < const Duration(hours: 2)) {
          try {
            return UserProfile.fromJson(jsonDecode(cachedJson));
          } catch (_) { } // Fallback to network on parse error
        }
      }
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/auth/me/');
      var headers = await _authHeaders();

      http.Response response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 401) {
        if (await _refreshToken()) {
          headers = await _authHeaders();
          response = await http.get(uri, headers: headers).timeout(_timeout);
        } else {
          throw Exception('Session expired. Please log in again.');
        }
      }

      if (response.statusCode == 200) {
        final jsonResponse = response.body;
        await prefs.setString('cached_profile', jsonResponse);
        await prefs.setString('profile_fetched_at', DateTime.now().toIso8601String());
        return UserProfile.fromJson(jsonDecode(jsonResponse));
      }
      throw Exception('Failed to load profile (${response.statusCode})');
    } catch (e) {
      // If network fails completely, try to return stale cache as fallback fallback
      final cachedJson = prefs.getString('cached_profile');
      if (cachedJson != null && !forceRefresh) {
         try {
           return UserProfile.fromJson(jsonDecode(cachedJson));
         } catch (_) {}
      }
      throw Exception(e.toString());
    }
  }

  static Future<void> updateProfile({String? firstName, String? lastName}) async {
    final body = <String, dynamic>{};
    if (firstName != null && firstName.isNotEmpty) body['first_name'] = firstName;
    if (lastName != null && lastName.isNotEmpty) body['last_name'] = lastName;
    
    // Safety check
    if (body.isEmpty) return;

    try {
      final uri = Uri.parse('$_baseUrl/api/auth/me/');
      var headers = await _authHeaders();

      var response = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);

      if (response.statusCode == 401) {
        if (await _refreshToken()) {
          headers = await _authHeaders();
          response = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
        } else {
          throw Exception('Session expired. Please log in again.');
        }
      }

      if (response.statusCode == 200) {
        // Clear cached profile to force fetch on next load
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_profile');
        return;
      }
      throw Exception('Failed to update profile (${response.statusCode})');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> requestPasswordReset(String email) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/password-reset/');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'email': email});

      final response = await http.post(uri, headers: headers, body: body).timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
        throw Exception('Failed to request reset (${response.statusCode}).');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final uri = Uri.parse('$_baseUrl/api/auth/logout/');
        final headers = await _authHeaders();
        await http.post(
          uri,
          headers: headers,
          body: jsonEncode({'refresh': refreshToken}),
        ).timeout(_timeout);
      }
    } catch (e) {
      // Ignore network errors on logout, just clear local session
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      // Clear persistent caches
      await prefs.remove('cached_profile');
      await prefs.remove('profile_fetched_at');
      await prefs.remove('cached_timetable_entries');
      await prefs.remove('timetable_fetched_at');
      await prefs.remove('cached_chat_conversations');
      await prefs.remove('chat_conversations_fetched_at');
    }
  }

  static Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
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
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
