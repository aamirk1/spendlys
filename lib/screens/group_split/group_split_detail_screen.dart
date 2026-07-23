import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/controllers/group_split_controller.dart';
import 'package:spendly/models/group_split_model.dart';
import 'package:spendly/services/whatsapp_service.dart';
import 'package:spendly/utils/utils.dart';

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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
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
                      _buildHeaderCard(theme, formattedDate),
                      const SizedBox(height: 16),
                      _buildStatsCard(theme, collected, remaining, progress,
                          isCompleted, paidCount),
                      const SizedBox(height: 20),
                      Text(
                        'Contributions list',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.split.members.length,
                        itemBuilder: (context, index) {
                          final member = widget.split.members[index];
                          return _buildMemberTile(theme, member);
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

  Widget _buildHeaderCard(ThemeData theme, String formattedDate) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.split.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bill Date: $formattedDate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Split Type: ${widget.split.splitType.capitalizeFirst}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    ThemeData theme,
    double collected,
    double remaining,
    double progress,
    bool isCompleted,
    int paidCount,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                  theme,
                  'Total bill',
                  '₹${widget.split.totalAmount.toStringAsFixed(0)}',
                  Colors.black87,
                ),
                _buildStatColumn(
                  theme,
                  'Collected',
                  '₹${collected.toStringAsFixed(0)}',
                  isCompleted ? Colors.green : Colors.blue,
                ),
                _buildStatColumn(
                  theme,
                  'Remaining',
                  '₹${remaining.toStringAsFixed(0)}',
                  isCompleted ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                color: isCompleted ? Colors.green : AppColors.primary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Collected',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '$paidCount of ${widget.split.members.length} paid',
                  style: TextStyle(
                    color: theme.disabledColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      ThemeData theme, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.disabledColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(ThemeData theme, Member member) {
    return Obx(() {
      final isPaid = member.isPaid.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: isPaid,
                activeColor: Colors.green,
                onChanged: (_) => _togglePaid(member),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                        color: isPaid ? theme.disabledColor : null,
                      ),
                    ),
                    if (member.phone != null && member.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.phone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${member.shareAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                      color: isPaid ? theme.disabledColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        color: isPaid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isPaid) ...[
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.notifications_active_outlined,
                      color: Colors.orangeAccent),
                  onPressed: () => _showNotificationOptions(member),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
