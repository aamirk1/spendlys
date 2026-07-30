import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spendly/app/modules/profile/controllers/user_info_controller.dart';
import 'package:spendly/app/utils/utils.dart';

class ReferralBottomSheet extends StatelessWidget {
  const ReferralBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final userInfoController = Get.find<UserInfoController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Obx(() {
          final user = userInfoController.myUser.value;
          final code = user.referralCode ?? "N/A";
          final count = user.referralCount;
          final earnedDays = count * 30;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Gift Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 48,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'referral_title'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description (Hinglish logic details)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  "Share your referral code with others! When a new user successfully registers using your referral code, you will get 30 days of Premium Features completely FREE, and they will receive 15 days of Premium completely FREE.\n\nThis reward isn't just a one-time offer. For every successful referral, you'll earn another 30 days of Premium. The more you refer, the more free Premium days you accumulate!",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 16),

              // Referral Code Box
              Text(
                'your_referral_code'.tr.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: Colors.teal),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            Utils.showSnackbar(
                              'success'.tr,
                              'Referral code copied to clipboard!',
                              isError: false,
                            );
                          },
                          tooltip: 'copy'.tr,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded,
                              color: Colors.teal),
                          onPressed: () {
                            final message =
                                "DailyBachat app par register karte waqt mera referral code '$code' use karein aur payein 15 din ka Premium membership bilkul FREE! App link download karne ke liye visit karein: https://dailybachat.com";
                            Share.share(message);
                          },
                          tooltip: 'share'.tr,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'referral_count'.tr,
                      '$count',
                      Icons.people_alt_rounded,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'premium_days_earned'.tr,
                      '$earnedDays',
                      Icons.workspace_premium_rounded,
                      Colors.amber[800]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Steps Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'how_it_works'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Steps List
              _buildStepRow(
                context,
                'how_it_works_step1'.tr,
                Icons.share_rounded,
                Colors.teal,
              ),
              SizedBox(
                height: 16,
              ),
              // _buildStepDivider(),
              _buildStepRow(
                context,
                'how_it_works_step2'.tr,
                Icons.how_to_reg_rounded,
                Colors.blue,
              ),
              SizedBox(
                height: 16,
              ),
              // _buildStepDivider(),
              _buildStepRow(
                context,
                'how_it_works_step3'.tr,
                Icons.card_membership_rounded,
                Colors.amber[800]!,
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
      height: 20,
      width: 2,
      color: Colors.grey[300],
    );
  }
}
