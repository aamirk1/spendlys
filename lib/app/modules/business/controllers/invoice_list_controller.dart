import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/modules/business/controllers/business_home_controller.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/business/views/business_home_view.dart';

class InvoiceListController extends GetxController {
  final invoices = [].obs;
  final isLoading = true.obs;
  final isMoreLoading = false.obs;

  // Pagination
  int currentPage = 1;
  final int limit = 10;
  bool hasMoreData = true;
  final scrollController = ScrollController();

  // Search and Filter
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final selectedTab = 'All'.obs;
  final dateRange = Rxn<DateTimeRange>();

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
          return date
                  .isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
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

  int get totalCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .length;

  int get paidCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'paid')
      .length;

  double get paidAmount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .fold(
          0.0,
          (sum, inv) =>
              sum +
              (double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0));

  int get pendingCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) =>
          (inv['status'] ?? '').toString().toLowerCase() == 'pending' ||
          (inv['status'] ?? '').toString().toLowerCase() == 'partially_paid')
      .length;

  double get pendingAmount => invoices
          .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
          .where((inv) =>
              (inv['status'] ?? '').toString().toLowerCase() == 'pending' ||
              (inv['status'] ?? '').toString().toLowerCase() ==
                  'partially_paid')
          .fold(0.0, (sum, inv) {
        final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return sum + (total - paid);
      });

  int get overdueCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where(
          (inv) => (inv['status'] ?? '').toString().toLowerCase() == 'overdue')
      .length;

  double get overdueAmount => invoices
          .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
          .where((inv) =>
              (inv['status'] ?? '').toString().toLowerCase() == 'overdue')
          .fold(0.0, (sum, inv) {
        final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return sum + (total - paid);
      });

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
    setupScrollListener();
  }

  void setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (hasMoreData && !isMoreLoading.value && !isLoading.value) {
          fetchInvoices(loadMore: true);
        }
      }
    });
  }

  Future<void> fetchInvoices(
      {bool loadMore = false, bool refresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    if (refresh) {
      currentPage = 1;
      hasMoreData = true;
    }

    final endpoint = '/business/invoices?page=$currentPage&limit=$limit';
    final cacheKey = 'GET_$endpoint';

    if (!loadMore && !refresh) {
      final cachedData = LocalCacheService.getCache(cacheKey);
      if (cachedData != null && cachedData is List) {
        invoices.assignAll(cachedData);
        isLoading.value = false;
        return;
      }
    }

    if (!loadMore) {
      final cachedData = LocalCacheService.getCache(cacheKey);
      if (cachedData != null && cachedData is List) {
        invoices.assignAll(cachedData);
      } else {
        isLoading.value = true;
      }
    } else {
      isMoreLoading.value = true;
    }

    try {
      final response =
          await ApiService.get(endpoint, headers: {'x-user-id': userId});

      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          final List newData = jsonDecode(response.body);

          if (refresh || !loadMore) {
            invoices.assignAll(newData);
          } else {
            invoices.addAll(newData);
          }

          if (newData.length < limit) {
            hasMoreData = false;
          } else {
            currentPage++;
          }
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load invoices: $e");
    } finally {
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }

  List get filteredInvoices {
    return invoices.where((inv) {
      final matchesSearch = (inv['invoice_number'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          (inv['customer']?['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());

      final rawStatus = (inv['status'] ?? '').toString().toLowerCase();
      bool matchesStatus = true;
      if (selectedTab.value == 'Paid') {
        matchesStatus = rawStatus == 'paid';
      } else if (selectedTab.value == 'Pending') {
        matchesStatus = rawStatus == 'pending' || rawStatus == 'partially_paid';
      } else if (selectedTab.value == 'Overdue') {
        matchesStatus = rawStatus == 'overdue';
      }

      bool matchesDate = true;
      if (dateRange.value != null && inv['date'] != null) {
        final d = DateTime.parse(inv['date']);
        matchesDate = d.isAfter(
                dateRange.value!.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.delete('/business/invoices/$invoiceId',
          headers: {'x-user-id': userId});

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Invoice deletion scheduled offline. Will sync when online."
                : "Invoice deleted successfully",
            isError: false);
        invoices.removeWhere((inv) => inv['id'].toString() == invoiceId);
        fetchInvoices(refresh: true);
        if (Get.isRegistered<BusinessHomeController>()) {
          Get.find<BusinessHomeController>().fetchSummary();
        }
      } else {
        Utils.showSnackbar(
            "Error", "Failed to delete invoice: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to delete invoice: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return {
          'label': 'Paid',
          'color': const Color(0xFF4CAF50),
          'bgColor': const Color(0xFFE8F5E9),
          'iconColor': const Color(0xFF4CAF50),
          'iconBgColor': const Color(0xFFE8F5E9),
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'overdue':
        return {
          'label': 'Overdue',
          'color': const Color(0xFFF44336),
          'bgColor': const Color(0xFFFFEBEE),
          'iconColor': const Color(0xFFF44336),
          'iconBgColor': const Color(0xFFFFCDD2).withValues(alpha: 0.5),
          'icon': Icons.warning_amber_rounded,
        };
      case 'partially_paid':
        return {
          'label': 'Partially Paid',
          'color': const Color(0xFF2196F3),
          'bgColor': const Color(0xFFE3F2FD),
          'iconColor': const Color(0xFF2196F3),
          'iconBgColor': const Color(0xFFE3F2FD),
          'icon': Icons.hourglass_bottom_rounded,
        };
      case 'pending':
      default:
        return {
          'label': 'Pending',
          'color': const Color(0xFFFF9800),
          'bgColor': const Color(0xFFFFF3E0),
          'iconColor': const Color(0xFF5F33E1),
          'iconBgColor': const Color(0xFFF3EFFF),
          'icon': Icons.description_rounded,
        };
    }
  }
}
