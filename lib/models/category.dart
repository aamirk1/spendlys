
import 'package:spendly/models/myuser.dart';


class Category {
  MyUser userId;
  String categoryId;
  String name;
  int totalExpenses;
  String icon;
  int color;

  Category({
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.totalExpenses,
    required this.icon,
    required this.color,
  });

  static final empty =
      Category(userId: MyUser.empty, categoryId: '', name: '', totalExpenses: 0, icon: '', color: 0);

  // CategoryEntity toEntity() {
  //   return CategoryEntity(
  //     categoryId: categoryId,
  //     name: name,
  //     totalExpenses: totalExpenses,
  //     icon: icon,
  //     color: color,
  //   );
  // }

  // static Category fromEntity(CategoryEntity entity) {
  //   return Category(
  //     userId: MyUser.empty,
  //     categoryId: entity.categoryId,
  //     name: entity.name,
  //     totalExpenses: entity.totalExpenses,
  //     icon: entity.icon,
  //     color: entity.color,
  //   );
  // }
}
