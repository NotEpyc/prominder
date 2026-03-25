import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_text_field.dart';
import '../../widgets/global_loader.dart';
import 'mobile_home_screen.dart';
import 'mobile_login_screen.dart';
import '../../widgets/neumorphic_alert.dart';

class MobileRegisterScreen extends StatefulWidget {
  const MobileRegisterScreen({super.key});

  @override
  State<MobileRegisterScreen> createState() => _MobileRegisterScreenState();
}

class _MobileRegisterScreenState extends State<MobileRegisterScreen> {
  // Checkbox boolean
  bool _agreeToTerms = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/login-screen.mp4';
      final file = File(videoPath);

      if (!await file.exists()) {
        final byteData = await rootBundle.load(
          'assets/videos/login-screen.mp4',
        );
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        await file.writeAsBytes(bytes);
      }

      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      showNeumorphicAlert(
        context,
        title: 'Empty Fields',
        message: 'Please fill out all fields to create your account.',
      );
      return;
    }

    if (!_agreeToTerms) {
      showNeumorphicAlert(
        context,
        title: 'Terms Required',
        message: 'Please agree to the terms and conditions before signing up.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const baseUrl = 'https://prominder.up.railway.app';

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Connection timed out. The server may be waking up — please try again.'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Register endpoint only returns user info (no tokens).
        // Auto-login with the same credentials to get tokens.
        final tokenResponse = await http.post(
          Uri.parse('$baseUrl/api/auth/token/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Auto-login after register timed out.'),
        );

        if (tokenResponse.statusCode == 200) {
          final tokenData = jsonDecode(tokenResponse.body);
          final prefs = await SharedPreferences.getInstance();
          if (tokenData['access'] != null) {
            await prefs.setString('access_token', tokenData['access']);
          }
          if (tokenData['refresh'] != null) {
            await prefs.setString('refresh_token', tokenData['refresh']);
          }
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MobileHomeScreen()),
            );
          }
        } else {
          // If auto login fails for some reason despite successful registration, route to login screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          showNeumorphicAlert(
            context,
            title: 'Registration Failed',
            message: 'This email may already be in use, or your details are invalid. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final String message;
        if (e is TimeoutException) {
          message = 'The server took too long to respond. It may be waking up — please try again in a moment.';
        } else if (e is SocketException || e.toString().contains('Failed host lookup')) {
          message = 'Could not reach the server. Please check your internet connection.';
        } else {
          message = 'Something went wrong. Please try again.\n\nDebug: ${e.toString()}';
        }
        showNeumorphicAlert(
          context,
          title: 'Connection Error',
          message: message,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          if (!_isVideoInitialized) const GlobalLoader(),
          AnimatedOpacity(
            opacity: _isVideoInitialized ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
        child: Stack(
          children: [
            // Background Video Layer
            SizedBox.expand(
              child:
                  _isVideoInitialized
                      ? FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                      : Container(color: AppTheme.backgroundColor),
            ),

            // Foreground Overlays
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimal Top-Left Logo Card
                  _buildTopLogoCard(context),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  offset: const Offset(0, 20),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 32.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  'Sign Up',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                    fontSize: 28,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // First Name Field
                                NeumorphicTextField(
                                  hintText: 'First Name',
                                  controller: _firstNameController,
                                ),

                                const SizedBox(height: 20),
                                
                                // Last Name Field
                                NeumorphicTextField(
                                  hintText: 'Last Name',
                                  controller: _lastNameController,
                                ),

                                const SizedBox(height: 20),

                                // Email Field
                                NeumorphicTextField(
                                  hintText: 'Your email here',
                                  controller: _emailController,
                                ),

                                const SizedBox(height: 20),

                                // Password Field
                                NeumorphicTextField(
                                  hintText: 'Your password here',
                                  obscureText: _obscurePassword,
                                  controller: _passwordController,
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppTheme.descriptionTextColor,
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Terms and conditions checkbox
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _agreeToTerms = !_agreeToTerms;
                                        });
                                      },
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              offset: const Offset(2, 2),
                                              blurRadius: 4,
                                            ),
                                            const BoxShadow(
                                              color:
                                                  AppTheme.buttonHighlightColor,
                                              offset: Offset(-2, -2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child:
                                            _agreeToTerms
                                                ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: AppTheme.primaryColor,
                                                )
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'I agree to all ',
                                          style: TextStyle(
                                            color: AppTheme.descriptionTextColor
                                                .withOpacity(0.8),
                                            fontSize: 13,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: 'terms and conditions',
                                              style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 36),

                                // Main Button
                                Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: NeumorphicButton(
                                      onPressed:
                                          _isLoading ? () {} : _handleRegister,
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color:
                                                          AppTheme
                                                              .buttonTextColor,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : const Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppTheme.buttonTextColor,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Bottom Login Link
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  // Small standalone top-left Neumorphic card for the Logo
  Widget _buildTopLogoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/app-icon.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'PROMINDER',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
