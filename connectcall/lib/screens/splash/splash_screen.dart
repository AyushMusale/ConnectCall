import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import '../../services/firebase/session.service.dart';
import 'widgets/splash_background_painter.dart';
import 'widgets/splash_logo.dart';

/// ConnectCall Splash Screen
/// Displays the custom brand emblem, two-tone typography ("Connect-Call"),
/// tagline, and animated progress bar with setup status.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2400),
    this.autoNavigate = true,
    this.onInitializationComplete,
  });

  /// Duration of the splash screen loading sequence.
  final Duration duration;

  /// Whether to automatically navigate after the progress finishes.
  final bool autoNavigate;

  /// Optional callback invoked when the setup sequence completes.
  /// If null and [autoNavigate] is true, navigates to `/signup`.
  final VoidCallback? onInitializationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleCompletion();
      }
    });

    _controller.forward();
  }

  void _handleCompletion() {
    if (!mounted) return;
    if (widget.onInitializationComplete != null) {
      widget.onInitializationComplete!();
    } else if (widget.autoNavigate) {
      final hasSession = getIt.isRegistered<SessionService>()
          ? getIt<SessionService>().hasActiveSession()
          : false;
      context.go(hasSession ? '/home' : '/signup');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Adapt dimensions for small screen sizes
    final isCompact = screenHeight < 640;
    final logoSize = isCompact ? 100.0 : 124.0;
    final titleFontSize = isCompact ? 30.0 : 36.0;
    final subtitleFontSize = isCompact ? 14.0 : 16.0;
    final progressBarWidth = math.min(screenWidth * 0.75, 300.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // 1. Organic decorative curved background
          Positioned.fill(
            child: const CustomPaint(
              painter: SplashBackgroundPainter(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isCompact ? 20 : 40),

                      // Brand Emblem & Identity
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SplashLogo(size: logoSize),
                            SizedBox(height: isCompact ? 20 : 28),
                            // Brand typography: Connect-Call
                            Text.rich(
                              TextSpan(
                                text: 'Connect',
                                style: TextStyle(
                                  color: const Color(0xFF1E242E),
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                                children: [
                                  TextSpan(
                                    text: '-Call',
                                    style: TextStyle(
                                      color: const Color(0xFFFF6E00),
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Tagline
                            Text(
                              'Stay close, no matter the distance',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF757B88),
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isCompact ? 48 : 80),

                      // Animated Progress Bar & Setup Status
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final progress = _progressAnimation.value.clamp(0.0, 1.0);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Capsule progress bar
                              Container(
                                width: progressBarWidth,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE5D3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5200),
                                          Color(0xFFFF7A1A),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Setup status
                              Text(
                                'Setting things up for you...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF636A78),
                                  fontSize: isCompact ? 13.5 : 14.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: isCompact ? 20 : 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
