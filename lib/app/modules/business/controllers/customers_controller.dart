import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/utils/utils.dart';

class CustomersController extends GetxController {
  final customers = [].obs;
  final isLoading = false.obs;

  // Filters & Search
  final selectedTab = 'All'.obs; // 'All', 'Active', 'Inactive'
  final searchQuery = ''.obs;
  final selectedSort = 'Recent'.obs; // 'Recent', 'A-Z', 'Z-A'
  final selectedFilter = 'This Month'.obs;

  bool isWithinFilter(dynamic dateValue, String filter) {
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
