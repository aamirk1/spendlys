import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/app/common_widgets/custom_app_bar.dart';
import 'package:spendly/app/utils/colors.dart';
import 'package:spendly/app/modules/group_split/controllers/group_split_controller.dart';
import 'package:spendly/app/data/models/group_split_model.dart';
import 'package:spendly/app/data/models/myuser.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/group_split/widgets/bill_details_card.dart';
import 'package:spendly/app/modules/group_split/widgets/split_type_selector.dart';
import 'package:spendly/app/modules/group_split/widgets/member_form_card.dart';
import 'package:spendly/app/common_widgets/custom_button.dart';

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

  // Itemized expenses toggle & list
  bool _useDetailedExpenses = false;
  final List<GroupSplitExpense> _expenseItems = [];

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

  double _calculateTotalExpense() {
    double total = 0.0;
    for (var exp in _expenseItems) {
      total += exp.amount;
    }
    return total;
  }

  void _addExpenseItem(String name, double amount) {
    setState(() {
      _expenseItems.add(GroupSplitExpense(name: name, amount: amount));
      if (_useDetailedExpenses) {
        _amountController.text = _calculateTotalExpense().toStringAsFixed(2);
      }
    });
    _recalculateShares();
  }

  void _removeExpenseItem(int index) {
    setState(() {
      _expenseItems.removeAt(index);
      if (_useDetailedExpenses) {
        _amountController.text = _calculateTotalExpense().toStringAsFixed(2);
      }
    });
    _recalculateShares();
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
      expenses: RxList<GroupSplitExpense>.from(_expenseItems),
      createdAt: DateTime.now(),
    );

    Get.find<GroupSplitController>().addGroupSplit(newSplit);
  }

  void _showAddExpenseDialog() {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Expense Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Expense Description',
                    hintText: 'e.g. Hotel, Dinner, Cab',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FD),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter description' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: '0.00',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FD),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter amount';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Please enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          _addExpenseItem(
                            nameCtrl.text.trim(),
                            double.parse(amtCtrl.text.trim()),
                          );
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      BillDetailsCard(
                        titleController: _titleController,
                        amountController: _amountController,
                        selectedDate: _selectedDate,
                        onTapDate: () => _selectDate(context),
                        readOnly: _useDetailedExpenses,
                      ),
                      const SizedBox(height: 16),
                      // Itemized expenses toggle switch
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Itemized Expenses',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Add individual expenses for this trip',
                                      style: TextStyle(fontSize: 11, color: theme.disabledColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _useDetailedExpenses,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _useDetailedExpenses = val;
                                  if (val) {
                                    _amountController.text = _calculateTotalExpense().toStringAsFixed(2);
                                  } else {
                                    _amountController.clear();
                                  }
                                });
                                _recalculateShares();
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Detailed itemized expenses list
                      if (_useDetailedExpenses) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Expenses list',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showAddExpenseDialog,
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Add Item'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: EdgeInsets.zero,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (_expenseItems.isEmpty) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'No items added yet. Tap "Add Item" to add trip expenses.',
                                    style: TextStyle(fontSize: 12, color: theme.disabledColor),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _expenseItems.length,
                                  itemBuilder: (context, index) {
                                    final exp = _expenseItems[index];
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹${exp.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                            onPressed: () => _removeExpenseItem(index),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      SplitTypeSelector(
                        currentSplitType: _splitType,
                        onSplitTypeChanged: (type) {
                          setState(() {
                            _splitType = type;
                          });
                          _recalculateShares();
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Members & Shares',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleMedium?.color ?? AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _addMemberItem(),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: const Text('Add Member'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                          final item = _memberItems[index];
                          return MemberFormCard(
                            index: index,
                            nameController: item.nameController,
                            phoneController: item.phoneController,
                            valueController: item.valueController,
                            isCreator: item.isCreator,
                            splitType: _splitType,
                            calculatedShare: item.calculatedShare,
                            onRemove: () => _removeMemberItem(index),
                            onValueChanged: _recalculateShares,
                          );
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
                    top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => CustomButton(
                            text: 'Save Split Group',
                            onPressed: _submit,
                            isLoading: Get.find<GroupSplitController>().isLoading.value,
                            backgroundColor: AppColors.primary,
                            borderRadius: 12,
                            height: 48,
                          )),
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
