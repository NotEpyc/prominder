import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic_button.dart';
import 'mobile_home_screen.dart';
import 'mobile_login_screen.dart';
import 'mobile_register_screen.dart';

class MobileLandingScreen extends StatefulWidget {
  const MobileLandingScreen({super.key});

  @override
  State<MobileLandingScreen> createState() => _MobileLandingScreenState();
}

class _MobileLandingScreenState extends State<MobileLandingScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Landing screen always shows on launch.
    // Token check only happens when user taps "Get Started".
  }

  Future<void> _initializeVideo() async {
    try {
      // Get the locally cached file path
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/landing-animation.mp4';
      final file = File(videoPath);

      // Cache it to phone's storage if it isn't there already
      if (!await file.exists()) {
        final byteData = await rootBundle.load(
          'assets/videos/landing-animation.mp4',
        );
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        await file.writeAsBytes(bytes);
      }

      // Initialize player with the cached local file
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
      // Video failed to load, will show fallback icon
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _navigateToGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MobileLoginScreen()),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MobileRegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine a reasonable max width for tablets/large phones
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 500.0 : screenWidth;

    return Scaffold(
      backgroundColor:
          AppTheme.backgroundColor, // Updated to Neumorphic background
      body: AnimatedOpacity(
        opacity: _isVideoInitialized ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 1), // Added spacer to push the video down
                  // Central Video (Edge to edge)
                  AspectRatio(
                    aspectRatio: 2464 / 1728,
                    child:
                        _isVideoInitialized
                            ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                            : Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 100,
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                  ),

                  const Spacer(flex: 1),

                  // Headlines & Bottom Actions
                  NeumorphicBottomPanel(
                    width: double.infinity,
                    height:
                        380, // Approximate height to fit the content cleanly
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Plan. Adapt. Achieve.',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.displayMedium?.copyWith(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI-powered study planning tailored to your needs. Bring consistency to your educational journey.',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.descriptionTextColor,
                              height: 1.5,
                              fontSize: 16,
                            ),
                          ),

                          const Spacer(),

                          SizedBox(
                            width: double.infinity,
                            child: NeumorphicButton(
                              onPressed: _navigateToGetStarted,
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.buttonTextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _navigateToRegister,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textColor,
                            ),
                            child: const Text(
                              "Don't Have An Account?",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicBottomPanel extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const NeumorphicBottomPanel({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: child,
    );
  }
}
