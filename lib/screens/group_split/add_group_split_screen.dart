import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/controllers/group_split_controller.dart';
import 'package:spendly/models/group_split_model.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/utils/utils.dart';

class AddGroupSplitScreen extends StatefulWidget {
  const AddGroupSplitScreen({super.key});

  @override
  State<AddGroupSplitScreen> createState() => _AddGroupSplitScreenState();
}

class _AddGroupSplitScreenState extends State<AddGroupSplitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _splitType = 'equal'; // 'equal', 'unequal', 'percentage'

  // We maintain a list of member controllers
  final List<_MemberFormItem> _memberItems = [];

  @override
  void initState() {
    super.initState();
    // Auto add the creator (the user) as the first member
    final myUser = MyUser.fromStorage();
    _addMemberItem(
      name: myUser.name.isEmpty ? 'You' : myUser.name,
      phone: myUser.phoneNumber,
      isCreator: true,
    );
    // Add one empty member to start with at least 2 members
    _addMemberItem();

    _amountController.addListener(_onAmountOrMembersChanged);
  }

  void _addMemberItem(
      {String name = '', String? phone, bool isCreator = false}) {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone ?? '');
    final valueCtrl = TextEditingController(); // For unequal/percentage inputs

    setState(() {
      _memberItems.add(_MemberFormItem(
        nameController: nameCtrl,
        phoneController: phoneCtrl,
        valueController: valueCtrl,
        isCreator: isCreator,
      ));
    });
    _onAmountOrMembersChanged();
  }

  void _removeMemberItem(int index) {
    if (_memberItems[index].isCreator) {
      Utils.showSnackbar('Warning', 'You cannot remove yourself from the split',
          isError: true);
      return;
    }
    setState(() {
      _memberItems.removeAt(index);
    });
    _onAmountOrMembersChanged();
  }

  void _onAmountOrMembersChanged() {
    if (_splitType == 'equal') {
      final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      final int count = _memberItems.length;
      if (count > 0 && totalAmount > 0) {
        final share = totalAmount / count;
        for (var item in _memberItems) {
          item.calculatedShare = share;
        }
      } else {
        for (var item in _memberItems) {
          item.calculatedShare = 0.0;
        }
      }
      setState(() {});
    }
  }

  void _recalculateShares() {
    final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (_splitType == 'equal') {
      _onAmountOrMembersChanged();
    } else if (_splitType == 'percentage') {
      for (var item in _memberItems) {
        final pct = double.tryParse(item.valueController.text) ?? 0.0;
        item.calculatedShare = (pct / 100.0) * totalAmount;
      }
      setState(() {});
    } else if (_splitType == 'unequal') {
      for (var item in _memberItems) {
        final val = double.tryParse(item.valueController.text) ?? 0.0;
        item.calculatedShare = val;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (var item in _memberItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _validateSplits() {
    final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      Utils.showSnackbar('Error', 'Please enter a valid total amount',
          isError: true);
      return false;
    }

    if (_memberItems.length < 2) {
      Utils.showSnackbar('Error', 'Please add at least one other member',
          isError: true);
      return false;
    }

    // Validate that all names are entered
    for (int i = 0; i < _memberItems.length; i++) {
      if (_memberItems[i].nameController.text.trim().isEmpty) {
        Utils.showSnackbar('Error', 'Member #${i + 1} must have a name',
            isError: true);
        return false;
      }
    }

    if (_splitType == 'unequal') {
      double sum = 0.0;
      for (var item in _memberItems) {
        final val = double.tryParse(item.valueController.text) ?? 0.0;
        if (val <= 0) {
          Utils.showSnackbar('Error', 'Enter share amount for all members',
              isError: true);
          return false;
        }
        sum += val;
      }
      if ((sum - totalAmount).abs() > 0.01) {
        Utils.showSnackbar('Error',
            'Sum of individual shares (₹${sum.toStringAsFixed(2)}) must equal Total Bill (₹${totalAmount.toStringAsFixed(2)})',
            isError: true);
        return false;
      }
    } else if (_splitType == 'percentage') {
      double sumPct = 0.0;
      for (var item in _memberItems) {
        final pct = double.tryParse(item.valueController.text) ?? 0.0;
        if (pct <= 0) {
          Utils.showSnackbar('Error', 'Enter percentage for all members',
              isError: true);
          return false;
        }
        sumPct += pct;
      }
      if ((sumPct - 100.0).abs() > 0.01) {
        Utils.showSnackbar('Error',
            'Sum of percentages ($sumPct%) must equal 100%',
            isError: true);
        return false;
      }
    }

    return true;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateSplits()) return;

    _recalculateShares();

    final List<Member> membersList = _memberItems.map((item) {
      return Member(
        name: item.nameController.text.trim(),
        phone: item.phoneController.text.trim().isEmpty
            ? null
            : item.phoneController.text.trim(),
        shareAmount: item.calculatedShare,
        paidAmount: (item.isCreator ? item.calculatedShare : 0.0).obs,
        isPaid: item.isCreator.obs, // Creator is marked paid by default
      );
    }).toList();

    final newSplit = GroupSplit(
      id: '',
      userId: '',
      title: _titleController.text.trim(),
      totalAmount: double.parse(_amountController.text),
      splitType: _splitType,
      date: _selectedDate,
      members: RxList<Member>.from(membersList),
      createdAt: DateTime.now(),
    );

    Get.find<GroupSplitController>().addGroupSplit(newSplit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

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
        title: 'New Group Split',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBillDetailsCard(theme, formattedDate),
                      const SizedBox(height: 16),
                      _buildSplitTypeSelector(theme),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Members & Shares',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _addMemberItem(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Member'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _memberItems.length,
                        itemBuilder: (context, index) {
                          return _buildMemberFormCard(theme, index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Split Group',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard(ThemeData theme, String formattedDate) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill details',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Activity / Title',
                hintText: 'e.g. Goa Trip, Dinner, Movie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Total Bill Amount',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter total amount';
                }
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.hintColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.hintColor),
                        const SizedBox(width: 12),
                        Text(
                          'Bill Date',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeBtn('equal', 'Equally', Icons.pie_chart),
            const SizedBox(width: 8),
            _buildTypeBtn('unequal', 'Custom', Icons.dashboard_customize),
            const SizedBox(width: 8),
            _buildTypeBtn('percentage', 'Percentage', Icons.percent),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeBtn(String type, String label, IconData icon) {
    final isSelected = _splitType == type;
    final theme = Theme.of(context);

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _splitType = type;
          });
          _recalculateShares();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.primary : theme.dividerColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : theme.iconTheme.color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberFormCard(ThemeData theme, int index) {
    final item = _memberItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: item.nameController,
                          enabled: !item.isCreator, // Can't rename Yourself
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Name',
                            prefixIcon: Icon(Icons.person, size: 18),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Name required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: item.phoneController,
                          enabled: !item.isCreator,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone, size: 18),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_splitType != 'equal') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: item.valueController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: _splitType == 'percentage'
                                  ? 'Percentage %'
                                  : 'Amount Share ₹',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            onChanged: (_) => _recalculateShares(),
                          ),
                        ),
                        if (_splitType == 'percentage') ...[
                          const SizedBox(width: 12),
                          Text(
                            'Calculated: ₹${item.calculatedShare.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right_alt,
                            size: 16, color: theme.disabledColor),
                        const SizedBox(width: 4),
                        Text(
                          'Share: ₹${item.calculatedShare.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.disabledColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!item.isCreator) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeMemberItem(index),
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberFormItem {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController valueController;
  final bool isCreator;
  double calculatedShare = 0.0;

  _MemberFormItem({
    required this.nameController,
    required this.phoneController,
    required this.valueController,
    required this.isCreator,
  });

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    valueController.dispose();
  }
}
