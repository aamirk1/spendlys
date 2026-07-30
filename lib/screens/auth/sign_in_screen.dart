import 'dart:math' as math;
import 'dart:ui';
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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Ensure we are in login mode
    controller.authMode.value = AuthMode.login;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: Icon(
      //       CupertinoIcons.back,
      //       color: isDark ? Colors.white : AppColors.textPrimary,
      //     ),
      //     onPressed: () => Get.back(),
      //   ),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: Stack(
        children: [
          // Background ambient decoration
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(isDark ? 0.05 : 0.02),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Top Header
                        Center(
                          child: Column(
                            children: [
                              // App Logo
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withOpacity(isDark ? 0.15 : 0.08),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logos/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'DailyBachat',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Welcome Back 👋',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in to manage your finances',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Toggle Login Mode (Email vs Phone)
                              _buildModeToggle(),
                              const SizedBox(height: 20),

                              // Fields Section
                              Obx(() => AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: controller.isEmailLogin.value
                                        ? _buildEmailFields(isDark)
                                        : _buildPhoneFields(isDark),
                                  )),
                              const SizedBox(height: 24),

                              // Login/OTP CTA Button
                              Obx(() => _PremiumButton(
                                    text: controller.isEmailLogin.value
                                        ? 'Sign In'
                                        : 'Send OTP',
                                    isLoading: controller.signInRequired.value,
                                    onPressed: _handleMainAction,
                                  )),

                              const SizedBox(height: 20),

                              // Go to register
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "New to DailyBachat? ",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.offNamed(RoutesName.signupView);
                                      },
                                      child: const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Security Shield Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.lock_shield_fill,
                              size: 14,
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '256-bit encrypted · Your data is safe',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : AppColors.textSecondary.withOpacity(0.5),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              _buildToggleTab('Email', controller.isEmailLogin.value, () {
                controller.isEmailLogin.value = true;
              }),
              _buildToggleTab('Phone / OTP', !controller.isEmailLogin.value,
                  () {
                controller.isEmailLogin.value = false;
              }),
            ],
          ),
        ));
  }

  Widget _buildToggleTab(String title, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
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
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white38 : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailFields(bool isDark) {
    return Column(
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
          validator: (v) => !v!.contains('@') ? 'Enter a valid email' : null,
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
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
              ),
              trailingAction: GestureDetector(
                onTap: () => Get.toNamed(RoutesName.forgotPasswordView),
                child: const Text(
                  'Forgot?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            )),
      ],
    );
  }

  Widget _buildPhoneFields(bool isDark) {
    return Column(
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
          validator: (v) => v!.length != 10 ? 'Enter valid number' : null,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.15),
            ),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.info_circle_fill,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "We'll send a one-time verification code",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleMainAction() async {
    if (controller.isEmailLogin.value) {
      await controller.signIn();
    } else {
      controller.isSigningUpFlow.value = false;
      await controller.sendOTP();
    }
  }
}

class _PremiumField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isFocused
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : AppColors.textSecondary),
                letterSpacing: 0.5,
              ),
            ),
            if (widget.trailingAction != null) widget.trailingAction!,
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08)),
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 12,
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
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.02),
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  widget.icon,
                  color: _isFocused
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.black.withOpacity(0.3)),
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
}

class _PremiumButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final Future<void> Function()? onPressed;

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
  bool _innerLoading = false;
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

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _innerLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _innerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool loading = widget.isLoading || _innerLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => widget.onPressed != null && !loading
          ? setState(() => _isPressed = true)
          : null,
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!loading && widget.onPressed != null) _handlePress();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: (widget.onPressed != null && !loading)
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: (widget.onPressed != null && !loading)
                ? null
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08)),
            boxShadow: (widget.onPressed != null && !loading)
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Opacity(
            opacity: (widget.onPressed != null && !loading) ? 1.0 : 0.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (!loading)
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
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.0),
                              ],
                            ).createShader(bounds),
                            child: Container(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  Center(
                    child: loading
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
                                size: 16,
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
