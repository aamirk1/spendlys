import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/utils/business_export_helper.dart';
import 'package:spendly/widgets/premium_dialogs.dart';
import 'package:spendly/res/routes/routes_name.dart';

class CustomersController extends GetxController {
  final customers = [].obs;
  final isLoading = false.obs;

  // Filters & Search
  final selectedTab = 'All'.obs; // 'All', 'Active', 'Inactive'
  final searchQuery = ''.obs;
  final selectedSort = 'Recent'.obs; // 'Recent', 'A-Z', 'Z-A'
  final selectedFilter = 'This Month'.obs;

  bool _isWithinFilter(dynamic dateValue, String filter) {
    if (dateValue == null) return false;
    try {
      final DateTime date = dateValue is DateTime
          ? dateValue
          : DateTime.parse(dateValue.toString());
      final now = DateTime.now();
      switch (filter) {
        case 'This Week':
          final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysToSubtract));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endOfWeek);
        case 'This Month':
          return date.year == now.year && date.month == now.month;
        case 'This Year':
          return date.year == now.year;
        default:
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  // For adding
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  List get filteredCustomers {
    List list = [...customers];

    // Apply Tab Filter
    if (selectedTab.value == 'Active') {
      list = list
          .where((c) =>
              (c['total_sales'] ?? 0.0) > 0 || (c['pending_amount'] ?? 0.0) > 0)
          .toList();
    } else if (selectedTab.value == 'Inactive') {
      list = list
          .where((c) =>
              (c['total_sales'] ?? 0.0) == 0 &&
              (c['pending_amount'] ?? 0.0) == 0)
          .toList();
    }

    // Apply Search Filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        final address = (c['address'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            address.contains(query);
      }).toList();
    }

    // Apply Sorting
    if (selectedSort.value == 'A-Z') {
      list.sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    } else if (selectedSort.value == 'Z-A') {
      list.sort((a, b) =>
          (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
    } else {
      list.sort((a, b) {
        final aDate = a['created_at'] != null
            ? DateTime.parse(a['created_at'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b['created_at'] != null
            ? DateTime.parse(b['created_at'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    }

    return list;
  }

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers({bool forceRefresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/business/customers';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (!forceRefresh && cachedData != null && cachedData is List) {
      customers.value = List<Map<String, dynamic>>.from(cachedData);
      return;
    }

    if (cachedData != null && cachedData is List) {
      customers.value = List<Map<String, dynamic>>.from(cachedData);
    } else {
      isLoading.value = true;
    }

    try {
      final response = await ApiService.get('/business/customers',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          customers.value = jsonDecode(response.body);
        }
      } else if (response.statusCode == 400 &&
          response.body.contains("business profile first")) {
        // Not configured yet
        Utils.showSnackbar(
            "Setup Required", "Please complete your Business Profile first.",
            isError: true);
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load customers: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer() async {
    if (!formKey.currentState!.validate()) return;

    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.back(); // Close bottom sheet
    isLoading.value = true;
    try {
      final response = await ApiService.post('/business/customers', headers: {
        'Content-Type': 'application/json',
        'x-user-id': userId
      }, body: {
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Customer added offline. Will sync when online."
                : "Customer added successfully",
            isError: false);
        nameController.clear();
        phoneController.clear();
        emailController.clear();
        addressController.clear();
        fetchCustomers(forceRefresh: true);
      } else {
        Utils.showSnackbar("Error", "Failed to add customer: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCustomer(String customerId) async {
    if (!formKey.currentState!.validate()) return;

    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.back(); // Close screen/sheet
    isLoading.value = true;
    try {
      final response =
          await ApiService.put('/business/customers/$customerId', headers: {
        'Content-Type': 'application/json',
        'x-user-id': userId
      }, body: {
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Customer updated offline. Will sync when online."
                : "Customer updated successfully",
            isError: false);
        nameController.clear();
        phoneController.clear();
        emailController.clear();
        addressController.clear();
        fetchCustomers(forceRefresh: true);
      } else {
        Utils.showSnackbar(
            "Error", "Failed to update customer: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.delete(
          '/business/customers/$customerId',
          headers: {'x-user-id': userId});

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Customer deletion scheduled offline. Will sync when online."
                : "Customer deleted successfully",
            isError: false);
        fetchCustomers(forceRefresh: true);
      } else {
        Utils.showSnackbar(
            "Error", "Failed to delete customer: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to delete customer: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

class CustomersListView extends StatelessWidget {
  const CustomersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomersController());
    final Color primaryColor =
        const Color(0xFF5F33E1); // Premium Deep Purple/Indigo

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Customers",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage all your customers",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          Padding(
            padding:
                const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0),
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(RoutesName.addCustomer),
              icon:
                  const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              label: const Text("Add Customer",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Statistics Row
            Obx(() {
              final filteredForStats = controller.customers
                  .where((c) => controller._isWithinFilter(c['created_at'], controller.selectedFilter.value))
                  .toList();
              final double dueAmount = controller.customers
                  .fold(0.0, (sum, c) => sum + (c['pending_amount'] ?? 0.0));
              final double totalSales = filteredForStats
                  .fold(0.0, (sum, c) => sum + (c['total_sales'] ?? 0.0));
              final int totalCust = controller.customers.length;
              final int activeCust = filteredForStats
                  .where((c) =>
                      (c['total_sales'] ?? 0.0) > 0 ||
                      (c['pending_amount'] ?? 0.0) > 0)
                  .length;
              final int dueCustCount = controller.customers
                  .where((c) => (c['pending_amount'] ?? 0.0) > 0)
                  .length;

              return Container(
                height: 125,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.people_outline_rounded,
                        color: Colors.purple,
                        title: "Total Customers",
                        value: "$totalCust",
                        subtitle: "All Time",
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.person_add_alt_1_outlined,
                        color: Colors.green,
                        title: "Active Customers",
                        value: "$activeCust",
                        subtitle: PopupMenuButton<String>(
                          initialValue: controller.selectedFilter.value,
                          onSelected: (String value) {
                            controller.selectedFilter.value = value;
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (BuildContext context) {
                            return ['This Week', 'This Month', 'This Year']
                                .map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(
                                  choice,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                controller.selectedFilter.value,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 11,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.history_toggle_off_rounded,
                        color: Colors.orange,
                        title: "Due from Customers",
                        value: "₹${dueAmount.toStringAsFixed(0)}",
                        subtitle: "$dueCustCount Customers",
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.wallet_outlined,
                        color: Colors.blue,
                        title: "Total Sales",
                        value: "₹${totalSales.toStringAsFixed(0)}",
                        subtitle: PopupMenuButton<String>(
                          initialValue: controller.selectedFilter.value,
                          onSelected: (String value) {
                            controller.selectedFilter.value = value;
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (BuildContext context) {
                            return ['This Week', 'This Month', 'This Year']
                                .map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(
                                  choice,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                controller.selectedFilter.value,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 11,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 2. Sliding Custom Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Obx(() => Row(
                    children: [
                      _buildTabButton(controller, 'All', "All"),
                      _buildTabButton(controller, 'Active', "Active"),
                      _buildTabButton(controller, 'Inactive', "Inactive"),
                    ],
                  )),
            ),
            const SizedBox(height: 14),

            // 3. Search and Sort Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border:
                            Border.all(color: Colors.grey.shade100, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: TextFormField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: "Search by name, phone or city...",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade400, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.grey.shade100, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedSort.value,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey),
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                                fontSize: 13),
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedSort.value = val;
                              }
                            },
                            items: ["Recent", "A-Z", "Z-A"]
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text("Sort: $s")))
                                .toList(),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Customers List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.customers.isEmpty) {
                  return Center(
                      child: CircularProgressIndicator(color: primaryColor));
                }
                final list = controller.filteredCustomers;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off_rounded,
                            size: 64, color: primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text("No matching customers found.",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                        .copyWith(bottom: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final cust = list[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child:
                                _buildCustomerCard(context, cust, primaryColor),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            // 5. Insights Banner and Bottom Actions Section
            _buildBottomDashboard(context, controller, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required dynamic subtitle,
  }) {
    // Generate HSL-based highlight colors
    final hslColor = HSLColor.fromColor(color);
    final bgColor = hslColor.withLightness(0.96).withSaturation(0.85).toColor();
    final borderColor =
        hslColor.withLightness(0.90).withSaturation(0.7).toColor();

    return Container(
      width: 135,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          subtitle is Widget
              ? subtitle
              : Text(
                  subtitle.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
      CustomersController controller, String val, String label) {
    final isSelected = controller.selectedTab.value == val;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectedTab.value = val,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color:
                  isSelected ? const Color(0xFF5F33E1) : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
      BuildContext context, dynamic cust, Color primaryColor) {
    final double sales = (cust['total_sales'] ?? 0.0).toDouble();
    final double pending = (cust['pending_amount'] ?? 0.0).toDouble();
    final bool hasDues = pending > 0;

    // Choose dynamic background avatar color based on customer name hash
    final String name = cust['name'] ?? 'Unknown';
    final int hash = name.codeUnits.fold(0, (sum, code) => sum + code);
    final List<Color> colorsList = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red
    ];
    final Color avatarColor = colorsList[hash % colorsList.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.toNamed(RoutesName.customerDetail, arguments: cust),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: avatarColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cust['phone'] ?? 'No phone number',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                      if (cust['address'] != null &&
                          cust['address'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                cust['address'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (sales > 0 || pending > 0)
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (sales > 0 || pending > 0) ? "Active" : "Inactive",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: (sales > 0 || pending > 0)
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Dues Balance
                    Text(
                      "₹${pending.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hasDues ? Colors.redAccent : Colors.green,
                      ),
                    ),
                    Text(
                      hasDues ? "Due in 3 days" : "No Due",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: hasDues
                            ? Colors.redAccent.withOpacity(0.7)
                            : Colors.green.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomDashboard(BuildContext context,
      CustomersController controller, Color primaryColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Insights Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withOpacity(0.12),
                  child: Icon(Icons.bar_chart_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Customer Insights",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text("Track customer dues and sales history in one place",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 10)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  child: const Text("View Insights",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Quick Actions
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Quick Actions",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quickActionItem(Icons.person_add_alt_1_rounded, "Add Customer",
                  () => Get.toNamed(RoutesName.addCustomer), primaryColor),
              _quickActionItem(
                  Icons.call_made_rounded, "WhatsApp", () {}, primaryColor),
              _quickActionItem(
                  Icons.email_outlined, "Email", () {}, primaryColor),
              _quickActionItem(Icons.notifications_active_outlined, "Reminder",
                  () {}, primaryColor),
              _quickActionItem(Icons.analytics_outlined, "Report", () {
                Get.bottomSheet(
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 20),
                        const Text("Export Customer Report",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.red),
                          title: const Text("Export as PDF"),
                          onTap: () {
                            Get.back();
                            _handleExport(context, controller, isPdf: true);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.table_view_rounded,
                              color: Colors.green),
                          title: const Text("Export as CSV"),
                          onTap: () {
                            Get.back();
                            _handleExport(context, controller, isPdf: false);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionItem(
      IconData icon, String label, VoidCallback onTap, Color primaryColor) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Future<void> _handleExport(
      BuildContext context, CustomersController controller,
      {required bool isPdf}) async {
    final paymentController = Get.put(PaymentController());
    if (!paymentController.isPremium.value) {
      PremiumDialogs.showPremiumRequiredDialog(
          message:
              "Exporting customer details is a premium feature. Upgrade now to unlock professional branding and unlimited exports.");
      return;
    }

    if (controller.customers.isEmpty) {
      Utils.showSnackbar("No Data", "There are no customers to export.");
      return;
    }

    Utils.showLoadingDialog();

    try {
      if (isPdf) {
        final pdfData = await BusinessExportHelper.generatePdfData(
          type: BusinessExportType.customers,
          data: controller.customers,
        );
        Get.back(); // Close loading dialog
        await BusinessExportHelper.showPrintPreview(
            pdfData, BusinessExportType.customers);
      } else {
        final csvPath = await BusinessExportHelper.generateCsvFile(
          type: BusinessExportType.customers,
          data: controller.customers,
        );
        Get.back(); // Close loading dialog
        await BusinessExportHelper.showShareSheet(
            csvPath, BusinessExportType.customers);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Utils.showSnackbar("Error", "Export failed: $e");
    }
  }
}
