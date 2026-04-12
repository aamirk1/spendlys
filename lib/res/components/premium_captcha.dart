import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';

class PremiumCaptcha extends StatefulWidget {
  final Function(bool) onVerified;

  const PremiumCaptcha({super.key, required this.onVerified});

  @override
  State<PremiumCaptcha> createState() => _PremiumCaptchaState();
}

class _PremiumCaptchaState extends State<PremiumCaptcha> {
  late String _captchaText;
  final TextEditingController _controller = TextEditingController();
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous chars
    _captchaText = String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(math.Random().nextInt(chars.length))),
    );
    _controller.clear();
    _isVerified = false;
    widget.onVerified(false);
    if (mounted) setState(() {});
  }

  void _checkCaptcha(String value) {
    if (value.toUpperCase() == _captchaText) {
      setState(() {
        _isVerified = true;
      });
      widget.onVerified(true);
    } else {
      if (_isVerified) {
        setState(() {
          _isVerified = false;
        });
        widget.onVerified(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Security Check",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Visual Captcha Box
              Container(
                height: 48,
                width: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Distortion lines
                      ...List.generate(5, (index) => Positioned(
                        left: math.Random().nextDouble() * 100,
                        top: math.Random().nextDouble() * 40,
                        child: Transform.rotate(
                          angle: math.Random().nextDouble() * 2,
                          child: Container(
                            width: 60,
                            height: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      )),
                      Text(
                        _captchaText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Refresh Icon
              IconButton(
                onPressed: _generateCaptcha,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 24),
              ),
              const Expanded(child: SizedBox()),
              // Verification Indicator
              if (_isVerified)
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          // Input Field
          TextField(
            controller: _controller,
            onChanged: _checkCaptcha,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Enter the code above",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isVerified ? Colors.greenAccent : Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isVerified ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isVerified ? Colors.greenAccent : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
