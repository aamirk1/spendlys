import 'package:spendly/models/category.dart';
import 'package:spendly/models/myuser.dart';

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
