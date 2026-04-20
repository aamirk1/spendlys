import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:spendly/controllers/auth_controller.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/utils/colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final bool fromSignIn = Get.arguments?['fromSignIn'] ?? false;

  // Background orb oscillation
  late final AnimationController _bgController;
  // Pulsing effect
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Staggered entry animations
  late final AnimationController _entryController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _pinFade;
  late final Animation<Offset> _pinSlide;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonScale;

  final TextEditingController otpController = TextEditingController();

  dynamic get controller =>
      fromSignIn ? Get.find<SignInController>() : Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat(reverse: true);

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    _pinFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _pinSlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Background & Orbs (Matching Premium Style) ──────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF04061A),
                    Color(0xFF0A0F2B),
                    Color(0xFF050A1E),
                  ],
                  stops: [0.0, 0.4 + _bgController.value * 0.2, 1.0],
                ),
              ),
            ),
          ),

          // Floating Orbs
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Stack(
              children: [
                _orb(
                  dx: size.width * 0.8 +
                      math.sin(_bgController.value * math.pi) * 40,
                  dy: size.height * 0.2,
                  radius: 120,
                  color: AppColors.primary.withOpacity(0.12),
                ),
                _orb(
                  dx: size.width * 0.1,
                  dy: size.height * 0.7 +
                      math.cos(_bgController.value * math.pi) * 30,
                  radius: 100,
                  color: AppColors.secondary.withOpacity(0.08),
                ),
              ],
            ),
          ),

          // ── Main Content ────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 20),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Verification Icon
                  FadeTransition(
                    opacity: _titleFade,
                    child: ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title & Subtitle
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          const Text(
                            "Verification",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "We've sent a 6-digit code to",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.phoneNumber.value,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // OTP Input
                  FadeTransition(
                    opacity: _pinFade,
                    child: SlideTransition(
                      position: _pinSlide,
                      child: Pinput(
                        length: 6,
                        controller: otpController,
                        onCompleted: (pin) => controller.verifyOTP(pin),
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 52,
                          height: 62,
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        submittedPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Verify Button
                  FadeTransition(
                    opacity: _buttonFade,
                    child: ScaleTransition(
                      scale: _buttonScale,
                      child: Obx(() => _PremiumButton(
                            text: "Verify & Login",
                            isLoading: controller.isLoading.value,
                            onPressed: () {
                              if (otpController.text.length == 6) {
                                controller.verifyOTP(otpController.text);
                              } else {
                                Get.snackbar(
                                    "Error", "Please enter 6-digit OTP",
                                    colorText: Colors.white,
                                    backgroundColor:
                                        Colors.red.withOpacity(0.4),
                                    snackPosition: SnackPosition.BOTTOM);
                              }
                            },
                          )),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Resend Option
                  FadeTransition(
                    opacity: _buttonFade,
                    child: Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.canResend.value
                                  ? "Didn't receive code? "
                                  : "Resend code in ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                            if (!controller.canResend.value)
                              Text(
                                "${controller.resendAfter.value}s",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            if (controller.canResend.value)
                              TextButton(
                                onPressed: () => controller
                                    .sendOTP(controller.phoneNumber.value),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  "Resend",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(
          {required double dx,
          required double dy,
          required double radius,
          required Color color}) =>
      Positioned(
        left: dx - radius,
        top: dy - radius,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      );
}

// ── Reusable Premium Components ────────────────────────────────────────────

class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const _PremiumButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
