import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/app/common_widgets/custom_app_bar.dart';
import 'package:spendly/app/utils/colors.dart';
import 'package:spendly/app/modules/group_split/controllers/group_split_controller.dart';
import 'package:spendly/app/data/models/group_split_model.dart';
import 'package:spendly/app/data/services/whatsapp_service.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/group_split/widgets/detail_header_card.dart';
import 'package:spendly/app/modules/group_split/widgets/detail_stats_card.dart';
import 'package:spendly/app/modules/group_split/widgets/member_contribution_tile.dart';

class GroupSplitDetailScreen extends StatefulWidget {
  final GroupSplit split;

  const GroupSplitDetailScreen({required this.split, super.key});

  @override
  State<GroupSplitDetailScreen> createState() => _GroupSplitDetailScreenState();
}

class _GroupSplitDetailScreenState extends State<GroupSplitDetailScreen> {
  late final GroupSplitController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<GroupSplitController>();
  }

  void _togglePaid(Member member) async {
    setState(() {
      member.isPaid.value = !member.isPaid.value;
      member.paidAmount.value = member.isPaid.value ? member.shareAmount : 0.0;
    });

    // Save changes to backend
    await _controller.updateGroupSplit(widget.split);
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Split Group?'),
        content: const Text(
            'This action will permanently delete this split group and all its contribution details. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // close dialog
              _controller.deleteGroupSplit(widget.split.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(Member member) {
    final String creatorName =
        widget.split.members.firstWhereOrNull((m) => m.name == 'You')?.name ??
            'the group creator';
    final String amount = member.shareAmount.toStringAsFixed(2);
    final String message =
        "Hey *${member.name}*, your share for *${widget.split.title}* is *₹$amount*. Please clear your contribution with *$creatorName*. Thank you! - sent via DailyBachat";

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remind ${member.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to send the contribution reminder:',
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildShareBtn(
                    label: 'WhatsApp',
                    icon: CupertinoIcons.phone_fill,
                    color: Colors.green,
                    onTap: () async {
                      Get.back();
                      final phone = member.phone ?? '';
                      if (phone.trim().isEmpty) {
                        Utils.showSnackbar(
                            'Error', 'No phone number provided for this member',
                            isError: true);
                        return;
                      }

                      // Try sending via backend WhatsApp templates
                      final creatorName = widget.split.members
                              .firstWhereOrNull((m) => m.name == 'You')
                              ?.name ??
                          'Creator';
                      final formattedDate =
                          DateFormat('yyyy-MM-dd').format(widget.split.date);

                      final success =
                          await WhatsAppService.sendGroupSplitReminder(
                        phone: phone,
                        recipientName: member.name,
                        amount: member.shareAmount,
                        title: widget.split.title,
                        creatorName: creatorName,
                        dueDate: formattedDate,
                      );

                      if (success) {
                        Utils.showSnackbar(
                            'Success', 'WhatsApp reminder sent successfully!',
                            isError: false);
                      } else {
                        // Fallback: Trigger manual WhatsApp link launching
                        final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                        final formattedPhone = cleanPhone.length == 10
                            ? '91$cleanPhone'
                            : cleanPhone;

                        final url = Uri.parse(
                          "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
                        );

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          await Share.share(message);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildShareBtn(
                    label: 'Share App',
                    icon: Icons.share,
                    color: AppColors.primary,
                    onTap: () async {
                      Get.back();
                      await Share.share(message);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd MMMM yyyy').format(widget.split.date);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        title: 'Split Details',
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          // Dynamic stats
          double collected = 0;
          int paidCount = 0;
          for (final member in widget.split.members) {
            if (member.isPaid.value) {
              collected += member.shareAmount;
              paidCount++;
            }
          }
          final remaining = widget.split.totalAmount - collected;
          final progress = widget.split.totalAmount > 0
              ? (collected / widget.split.totalAmount)
              : 0.0;
          final isCompleted = collected >= widget.split.totalAmount;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailHeaderCard(
                        title: widget.split.title,
                        formattedDate: formattedDate,
                        splitType: widget.split.splitType,
                      ),
                      const SizedBox(height: 16),
                      DetailStatsCard(
                        totalAmount: widget.split.totalAmount,
                        collected: collected,
                        remaining: remaining,
                        progress: progress,
                        isCompleted: isCompleted,
                        paidCount: paidCount,
                        totalMembers: widget.split.members.length,
                      ),
                      const SizedBox(height: 20),
                      
                      // Display individual expenses breakdown if they exist
                      if (widget.split.expenses.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Expenses breakdown',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleMedium?.color ?? AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.split.expenses.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: theme.dividerColor.withValues(alpha: 0.06),
                            ),
                            itemBuilder: (context, index) {
                              final exp = widget.split.expenses[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                  child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 16),
                                ),
                                title: Text(
                                  exp.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                trailing: Text(
                                  '₹${exp.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Contributions list',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color ?? AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.split.members.length,
                        itemBuilder: (context, index) {
                          final member = widget.split.members[index];
                          return MemberContributionTile(
                            member: member,
                            onTogglePaid: () => _togglePaid(member),
                            onNotify: () => _showNotificationOptions(member),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
