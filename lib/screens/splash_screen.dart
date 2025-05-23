import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:semuria/screens/auth_screen.dart';
import 'package:semuria/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _textController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animations
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Background gradient animation
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Text animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Start animations with delays
    _backgroundController.forward();

    Timer(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });

    Timer(const Duration(milliseconds: 1200), () {
      _textController.forward();
    });

    // Navigate after delay
    Timer(const Duration(seconds: 4), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const StartScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFFF8E6E0), // Soft peach
                    const Color(0xFFE8D5CF), // Warm beige
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFFFFFBF8), // Cream white
                    const Color(0xFFF5F2F0), // Soft off-white
                    _backgroundAnimation.value,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.3, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating particles/dots animation
                ...List.generate(20, (index) => _buildFloatingDot(index)),

                // Main content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with animations
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _logoRotationAnimation.value,
                            child: Transform.scale(
                              scale: _logoScaleAnimation.value,
                              child: FadeTransition(
                                opacity: _logoFadeAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFD4B5A0,
                                      ).withOpacity(0.4),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFD4B5A0,
                                        ).withOpacity(0.15),
                                        blurRadius: 20,
                                        spreadRadius: 3,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'images/hitam.png',
                                    width: 120,
                                    height: 120,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // App name with slide animation
                      SlideTransition(
                        position: _textSlideAnimation,
                        child: FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                'SEMURIA',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6B4E3D),
                                  letterSpacing: 3,
                                  fontFamily: 'playpen',
                                  shadows: [
                                    Shadow(
                                      color: const Color(
                                        0xFFD4B5A0,
                                      ).withOpacity(0.4),
                                      offset: const Offset(2, 2),
                                      blurRadius: 6,
                                    ),
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      offset: const Offset(-1, -1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading indicator
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Container(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF9C7B6B).withOpacity(0.7),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingDot(int index) {
    final random = index * 0.1;
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final progress = (_backgroundController.value + random) % 1.0;
        final size = MediaQuery.of(context).size;

        return Positioned(
          left:
              (size.width * (0.1 + (index % 5) * 0.2)) +
              (30 * (progress - 0.5)),
          top:
              (size.height * (0.1 + (index % 4) * 0.25)) +
              (20 * (progress - 0.5)),
          child: Opacity(
            opacity: (0.2 + 0.3 * (1 - progress)),
            child: Container(
              width: 4 + (index % 3) * 2,
              height: 4 + (index % 3) * 2,
              decoration: BoxDecoration(
                color: const Color(0xFFD4B5A0).withOpacity(0.4),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4B5A0).withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
