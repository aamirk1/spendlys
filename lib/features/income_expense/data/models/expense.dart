import 'package:spendly/features/category/data/models/category_model.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';

class Expense {
  MyUser userId;
  String expenseId;
  Category category;
  DateTime date;
  int amount;

  Expense({
    required this.userId,
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
  });

  static final empty = Expense(
    userId: MyUser.empty,
    expenseId: '',
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
  );
}
