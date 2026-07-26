import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_up_controller.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final controller = Get.put(SignUpController());

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _referralFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
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
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _referralFocus.dispose();
    _passwordFocus.dispose();
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                        const SizedBox(height: 10),
                        // Top Header
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'create_account'.tr,
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
                                'Join DailyBachat today and track your expenses effortlessly',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white54
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
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name
                              _PremiumField(
                                controller: controller.nameController,
                                focusNode: _nameFocus,
                                label: 'Full Name',
                                hint: 'John Doe',
                                icon: CupertinoIcons.person_fill,
                                keyboardType: TextInputType.name,
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter your name' : null,
                              ),
                              const SizedBox(height: 18),

                              // Mobile Number
                              _PremiumField(
                                controller: controller.phoneNumberController,
                                focusNode: _phoneFocus,
                                label: 'Mobile Number',
                                hint: '10-digit number',
                                icon: CupertinoIcons.phone_fill,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v!.isEmpty) {
                                    return 'Enter your phone number';
                                  }
                                  if (v.length != 10) {
                                    return 'Phone number must be 10 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Email Address
                              _PremiumField(
                                controller: controller.emailController,
                                focusNode: _emailFocus,
                                label: 'Email Address',
                                hint: 'example@mail.com',
                                icon: CupertinoIcons.mail_solid,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v!.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(v)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Referral Code (Optional)
                              _PremiumField(
                                controller: controller.referredByController,
                                focusNode: _referralFocus,
                                label: 'Referral Code (Optional)',
                                hint: 'Enter referral code',
                                icon: CupertinoIcons.gift_fill,
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 18),

                              // Password
                              Obx(() => _PremiumField(
                                    controller: controller.passwordController,
                                    focusNode: _passwordFocus,
                                    label: 'Password',
                                    hint: 'Create a strong password',
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
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v!.isEmpty) {
                                        return 'Create a password';
                                      }
                                      if (v.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  )),
                              const SizedBox(height: 16),

                              // Password Strength Meter
                              Obx(() => _buildStrengthRow(isDark)),
                              const SizedBox(height: 28),

                              // Submit Button
                              Obx(() => _PremiumButton(
                                    text: 'Create Account',
                                    isLoading: controller.signUpRequired.value,
                                    onPressed: () async {
                                      if (controller.formKey.currentState!
                                          .validate()) {
                                        await controller.signUp();
                                      }
                                    },
                                  )),

                              const SizedBox(height: 20),

                              // Go to Login
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.offNamed(RoutesName.loginView);
                                      },
                                      child: const Text(
                                        'Sign In',
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

  Widget _buildStrengthRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StrengthBadge(
                  label: '8+ Chars', isValid: controller.contains8Length.value),
              _StrengthBadge(
                  label: 'Uppercase',
                  isValid: controller.containsUpperCase.value),
              _StrengthBadge(
                  label: 'Lowercase',
                  isValid: controller.containsLowerCase.value),
              _StrengthBadge(
                  label: 'Number', isValid: controller.containsNumber.value),
              _StrengthBadge(
                  label: 'Special Char',
                  isValid: controller.containsSpecialChar.value),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrengthBadge extends StatelessWidget {
  final String label;
  final bool isValid;

  const _StrengthBadge({required this.label, required this.isValid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.green.withOpacity(isDark ? 0.15 : 0.08)
            : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isValid
              ? AppColors.green.withOpacity(isDark ? 0.4 : 0.3)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: isValid
                ? AppColors.green
                : (isDark ? Colors.white24 : Colors.black26),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isValid
                  ? (isDark ? AppColors.green : Colors.green.shade700)
                  : (isDark ? Colors.white24 : Colors.black38),
            ),
          ),
        ],
      ),
    );
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
  final String? Function(String?)? onChanged;
  final Widget? suffixWidget;

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
            onChanged: widget.onChanged,
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
