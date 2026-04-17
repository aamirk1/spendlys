import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final controller = Get.find<SignInController>();

  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _fieldsFade;
  late Animation<Offset> _fieldsSlide;
  late Animation<double> _btnScale;
  late Animation<double> _pulseAnim;

  // Password visibility driven via controller (reactive)
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _cardSlide = Tween<double>(begin: 120, end: 0).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutExpo,
    ));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _titleFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _fieldsFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));
    _fieldsSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _btnScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      _cardController.forward();
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Animated Gradient Background ──────────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF0A0E27),
                      Color(0xFF0D1B3E),
                      Color(0xFF0A1628),
                    ],
                    stops: [
                      0.0,
                      0.5 + _bgController.value * 0.2,
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Animated Orbs ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Stack(
                children: [
                  _buildOrb(
                    dx: size.width * 0.8 +
                        math.sin(_bgController.value * math.pi * 2) * 30,
                    dy: size.height * 0.1 +
                        math.cos(_bgController.value * math.pi * 2) * 20,
                    radius: 160,
                    color: AppColors.primary.withOpacity(0.18),
                  ),
                  _buildOrb(
                    dx: size.width * 0.1 +
                        math.cos(_bgController.value * math.pi * 2) * 25,
                    dy: size.height * 0.7 +
                        math.sin(_bgController.value * math.pi * 2) * 15,
                    radius: 130,
                    color: AppColors.secondary.withOpacity(0.12),
                  ),
                  _buildOrb(
                    dx: size.width * 0.5 +
                        math.sin(_bgController.value * math.pi) * 40,
                    dy: size.height * 0.35 +
                        math.cos(_bgController.value * math.pi) * 10,
                    radius: 80,
                    color: AppColors.tertiary.withOpacity(0.08),
                  ),
                ],
              );
            },
          ),

          // ── Floating Particles ────────────────────────────────────
          ...List.generate(
              8, (i) => _FloatingParticle(index: i, bgAnim: _bgController)),

          // ── Main Content ──────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: controller.formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ── Logo + Title ──────────────────────────────
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Column(
                            children: [
                              // Animated Logo
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (_, __) => Transform.scale(
                                  scale: _pulseAnim.value,
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary,
                                          AppColors.secondary,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.5),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/logos/logo.png',
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'DailyBachat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(() => AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Text(
                                      controller.authMode.value ==
                                              AuthMode.login
                                          ? 'Welcome Back 👋'
                                          : 'Join DailyBachat ✨',
                                      key: ValueKey(controller.authMode.value),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 6),
                              Obx(() => AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Text(
                                      controller.authMode.value ==
                                              AuthMode.login
                                          ? 'Sign in to manage your finances'
                                          : 'Start your financial journey today',
                                      key: ValueKey(
                                          'sub_${controller.authMode.value}'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white38,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Glass Card ────────────────────────────────
                      AnimatedBuilder(
                        animation: _cardController,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _cardSlide.value),
                          child: Opacity(
                            opacity: _cardFade.value,
                            child: child,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  // ── Toggle Tabs ─────────────────
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: _buildModeToggle(),
                                  ),
                                  const SizedBox(height: 28),

                                  // ── Animated Input Fields ────────
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: SlideTransition(
                                      position: _fieldsSlide,
                                      child: Obx(() => AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 450),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            transitionBuilder: (child, anim) {
                                              return FadeTransition(
                                                opacity: anim,
                                                child: SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin:
                                                        const Offset(0.06, 0),
                                                    end: Offset.zero,
                                                  ).animate(anim),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: controller.authMode.value ==
                                                    AuthMode.signup
                                                ? _buildSignupFields()
                                                : _buildLoginFields(),
                                          )),
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // ── Action Button ────────────────
                                  AnimatedBuilder(
                                    animation: _contentController,
                                    builder: (_, child) => Transform.scale(
                                      scale: _btnScale.value,
                                      child: child,
                                    ),
                                    child: Obx(() => _PremiumButton(
                                          text: _getButtonText(),
                                          isLoading:
                                              controller.signInRequired.value,
                                          onPressed: _handleMainAction,
                                        )),
                                  ),

                                  const SizedBox(height: 20),

                                  // ── Footer toggle ────────────────
                                  FadeTransition(
                                    opacity: _fieldsFade,
                                    child: Obx(() => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.authMode.value ==
                                                      AuthMode.login
                                                  ? "New to DailyBachat? "
                                                  : "Already have an account? ",
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 13,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: controller.toggleAuthMode,
                                              child: Text(
                                                controller.authMode.value ==
                                                        AuthMode.login
                                                    ? 'Create Account'
                                                    : 'Sign In',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
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
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Security Badge ────────────────────────────
                      FadeTransition(
                        opacity: _fieldsFade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.lock_shield_fill,
                              size: 14,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '256-bit encrypted · Your data is safe',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.3),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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

  // ── Mode Toggle ──────────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              _buildToggleTab('Sign In', AuthMode.login),
              _buildToggleTab('Register', AuthMode.signup),
            ],
          ),
        ));
  }

  Widget _buildToggleTab(String title, AuthMode mode) {
    final isSelected = controller.authMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.authMode.value = mode;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white38,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Login Fields ─────────────────────────────────────────────────────────
  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Method selector: Email / Phone
        Obx(() => Row(
              children: [
                _buildMethodChip('Email', controller.isEmailLogin.value,
                    () => controller.isEmailLogin.value = true),
                const SizedBox(width: 12),
                _buildMethodChip('Phone / OTP', !controller.isEmailLogin.value,
                    () => controller.isEmailLogin.value = false),
              ],
            )),
        const SizedBox(height: 22),
        Obx(() => AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0.05, 0), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: controller.isEmailLogin.value
                  ? Column(
                      key: const ValueKey('email_fields'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PremiumField(
                          controller: controller.emailController,
                          focusNode: _emailFocus,
                          label: 'Email Address',
                          hint: 'you@example.com',
                          icon: CupertinoIcons.mail_solid,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !v!.contains('@') ? 'Enter valid email' : null,
                        ),
                        const SizedBox(height: 18),
                        Obx(() => _PremiumField(
                              controller: controller.passwordController,
                              focusNode: _passwordFocus,
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: CupertinoIcons.lock_fill,
                              obscureText: controller.obscurePassword.value,
                              keyboardType: TextInputType.visiblePassword,
                              suffixWidget: GestureDetector(
                                onTap: controller.togglePasswordVisibility,
                                child: Icon(
                                  controller.obscurePassword.value
                                      ? CupertinoIcons.eye_slash_fill
                                      : CupertinoIcons.eye_fill,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                              trailingAction: GestureDetector(
                                onTap: () =>
                                    Get.toNamed(RoutesName.forgotPasswordView),
                                child: const Text(
                                  'Forgot?',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter password' : null,
                            )),
                      ],
                    )
                  : Column(
                      key: const ValueKey('phone_fields'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PremiumField(
                          controller: controller.phoneController,
                          focusNode: _phoneFocus,
                          label: 'Mobile Number',
                          hint: '10-digit number',
                          icon: CupertinoIcons.phone_fill,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v!.length != 10 ? 'Enter valid number' : null,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.info_circle,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "We'll send a one-time verification code",
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            )),
      ],
    );
  }

  // ── Signup Fields ────────────────────────────────────────────────────────
  Widget _buildSignupFields() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumField(
          controller: controller.nameController,
          focusNode: _nameFocus,
          label: 'Full Name',
          hint: 'John Doe',
          icon: CupertinoIcons.person_fill,
          keyboardType: TextInputType.name,
          validator: (v) => v!.isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 18),
        _PremiumField(
          controller: controller.phoneController,
          focusNode: _phoneFocus,
          label: 'Mobile Number',
          hint: '10-digit number',
          icon: CupertinoIcons.phone_fill,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v!.isEmpty) return 'Enter your phone number';
            if (v.length != 10) return 'Must be 10 digits';
            return null;
          },
        ),
        const SizedBox(height: 18),
        _PremiumField(
          controller: controller.emailController,
          focusNode: _emailFocus,
          label: 'Email Address',
          hint: 'you@example.com',
          icon: CupertinoIcons.mail_solid,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
        ),
        const SizedBox(height: 18),
        Obx(() => _PremiumField(
              controller: controller.passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              hint: 'Min 8 characters',
              icon: CupertinoIcons.lock_fill,
              obscureText: controller.obscurePassword.value,
              keyboardType: TextInputType.visiblePassword,
              onChanged: (v) {
                controller.checkPasswordStrength(v ?? '');
                return null;
              },
              suffixWidget: GestureDetector(
                onTap: controller.togglePasswordVisibility,
                child: Icon(
                  controller.obscurePassword.value
                      ? CupertinoIcons.eye_slash_fill
                      : CupertinoIcons.eye_fill,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
              validator: (v) =>
                  v!.length < 8 ? 'Min 8 characters required' : null,
            )),
        const SizedBox(height: 14),
        Obx(() => _buildStrengthRow()),
      ],
    );
  }

  Widget _buildStrengthRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _StrengthBadge(
            label: '8+ chars', isValid: controller.contains8Length.value),
        _StrengthBadge(
            label: 'Number', isValid: controller.containsNumber.value),
        _StrengthBadge(
            label: 'Uppercase', isValid: controller.containsUpperCase.value),
      ],
    );
  }

  Widget _buildMethodChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0085CC)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrb(
      {required double dx,
      required double dy,
      required double radius,
      required Color color}) {
    return Positioned(
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

  String _getButtonText() {
    if (controller.authMode.value == AuthMode.signup) {
      return 'Create Account';
    }
    return controller.isEmailLogin.value ? 'Sign In' : 'Send OTP';
  }

  void _handleMainAction() {
    if (controller.authMode.value == AuthMode.signup) {
      controller.handleSignUp();
    } else {
      if (controller.isEmailLogin.value) {
        controller.signIn();
      } else {
        controller.isSigningUpFlow.value = false;
        controller.sendOTP();
      }
    }
  }
}

// ── Floating Particle Widget ─────────────────────────────────────────────────
class _FloatingParticle extends StatefulWidget {
  final int index;
  final AnimationController bgAnim;

  const _FloatingParticle({required this.index, required this.bgAnim});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _x, _y, _size;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.index * 13 + 7);
    _x = rng.nextDouble();
    _y = rng.nextDouble();
    _size = rng.nextDouble() * 4 + 2;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Colors.white,
    ];
    _color = colors[widget.index % colors.length].withOpacity(0.3);

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5 + rng.nextInt(5)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final offset = math.sin(_ctrl.value * math.pi * 2 + widget.index) * 18;
        return Positioned(
          left: _x * size.width,
          top: _y * size.height + offset,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.5),
                  blurRadius: 6,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Premium Text Field ────────────────────────────────────────────────────────
class _PremiumField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? Function(String?)? onChanged;
  final Widget? suffixWidget;
  final Widget? trailingAction;

  const _PremiumField({
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    required this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffixWidget,
    this.trailingAction,
  });

  @override
  State<_PremiumField> createState() => _PremiumFieldState();
}

class _PremiumFieldState extends State<_PremiumField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(() {
      if (mounted) {
        setState(() => _isFocused = widget.focusNode!.hasFocus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.trailingAction != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(),
              widget.trailingAction!,
            ],
          )
        else
          _label(),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary.withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: TextInputAction.next,
            validator: widget.validator,
            onChanged: widget.onChanged,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  widget.icon,
                  color: _isFocused
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.35),
                  size: 20,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: widget.suffixWidget != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: widget.suffixWidget,
                    )
                  : null,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              errorStyle:
                  const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label() => Text(
        widget.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _isFocused ? AppColors.primary : Colors.white.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      );
}

// ── Password Strength Badge ───────────────────────────────────────────────────
class _StrengthBadge extends StatelessWidget {
  final String label;
  final bool isValid;

  const _StrengthBadge({required this.label, required this.isValid});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.green.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isValid
              ? AppColors.green.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: isValid ? AppColors.green : Colors.white24,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isValid ? AppColors.green : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Premium Gradient Button ───────────────────────────────────────────────────
class _PremiumButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PremiumButton({
    required this.text,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) =>
          widget.onPressed != null ? setState(() => _isPressed = true) : null,
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading && widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: widget.onPressed != null
                  ? [AppColors.primary, AppColors.secondary]
                  : [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.1)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Opacity(
            opacity: widget.onPressed != null ? 1.0 : 0.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Shimmer overlay
                  if (!widget.isLoading)
                    AnimatedBuilder(
                      animation: _shimCtrl,
                      builder: (_, __) {
                        return Positioned.fill(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment(-1.5 + _shimCtrl.value * 3.5, 0),
                              end: Alignment(-0.5 + _shimCtrl.value * 3.5, 0),
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.0),
                              ],
                            ).createShader(bounds),
                            child: Container(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  // Content
                  Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                CupertinoIcons.arrow_right,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
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
