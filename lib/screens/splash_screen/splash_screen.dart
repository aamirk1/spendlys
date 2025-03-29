import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

  final SplashController controller = Get.put(SplashController());

  // Define color constants
  static const Color primaryColor = Color(0xFF00B2E7);
  static const Color secondaryColor = Color(0xFFE064F7);
  static const Color tertiaryColor = Color(0xFFFF8D6C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensure full width
        height: double.infinity, // Ensure full height
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Logo
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut, // Adds a bouncy effect for scaling
                  builder: (context, double value, child) {
                    // Clamp the opacity value to ensure it stays between 0.0 and 1.0
                    final clampedOpacity = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale:
                          value, // Scale animation (can overshoot with elasticOut)
                      child: Opacity(
                        opacity:
                            clampedOpacity, // Use clamped value for opacity
                        child: SizedBox(
                          width: 250, // Adjust size as needed
                          height: 250,
                          child: Image.asset(
                            'assets/logos/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if the image fails to load
                              return const Icon(
                                Icons.error,
                                color: Colors.white,
                                size: 100,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // App Name with color transition, fade, and scale animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(
                      milliseconds: 3000), // Total duration for color cycle
                  builder: (context, value, child) {
                    // Calculate color based on the value (0.0 to 1.0)
                    Color textColor;
                    if (value < 0.33) {
                      // Transition from primaryColor to secondaryColor
                      textColor = Color.lerp(
                        primaryColor,
                        secondaryColor,
                        value / 0.33,
                      )!;
                    } else if (value < 0.66) {
                      // Transition from secondaryColor to tertiaryColor
                      textColor = Color.lerp(
                        secondaryColor,
                        tertiaryColor,
                        (value - 0.33) / 0.33,
                      )!;
                    } else {
                      // Transition from tertiaryColor back to primaryColor
                      textColor = Color.lerp(
                        tertiaryColor,
                        primaryColor,
                        (value - 0.66) / 0.34,
                      )!;
                    }

                    return Transform.scale(
                      scale: 0.8 + value * 0.2, // Scale from 0.8 to 1.0
                      child: Opacity(
                        opacity: value, // Fade-in animation
                        child: Text(
                          'DailyBachat',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            shadows: [
                              Shadow(
                                color: tertiaryColor.withOpacity(0.5),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Tagline with animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Text(
                        'Track Your Expenses Smartly',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Loading indicator
                CircularProgressIndicator(
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(tertiaryColor),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
