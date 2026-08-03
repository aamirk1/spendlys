import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/modules/business/controllers/business_home_controller.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/business/views/business_home_view.dart';

class QuotationListController extends GetxController {
  final quotations = [].obs;
  final isLoading = true.obs;

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

  int get totalCount => quotations
      .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
      .length;

  int get acceptedCount => quotations
          .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
          .where((q) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        return status == 'converted' || status == 'accepted';
      }).length;

  double get acceptedAmount => quotations
          .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
          .where((q) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        return status == 'converted' || status == 'accepted';
      }).fold(
              0.0,
              (sum, q) =>
                  sum +
                  (double.tryParse(q['total']?.toString() ?? '0') ?? 0.0));

  int get pendingCount => quotations
          .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
          .where((q) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        return status == 'sent' || status == 'draft' || status == 'pending';
      }).length;

  double get pendingAmount => quotations
          .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
          .where((q) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        return status == 'sent' || status == 'draft' || status == 'pending';
      }).fold(
              0.0,
              (sum, q) =>
                  sum +
                  (double.tryParse(q['total']?.toString() ?? '0') ?? 0.0));

  int get rejectedCount => quotations
          .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
          .where((q) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        return status == 'expired' || status == 'rejected';
      }).length;

  double get rejectedAmount => quotations
          .where((q) => _isWithinFilter(q['date'], selectedFilter.value))
          .where((q) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        return status == 'expired' || status == 'rejected';
      }).fold(
              0.0,
              (sum, q) =>
                  sum +
                  (double.tryParse(q['total']?.toString() ?? '0') ?? 0.0));

  List get filteredQuotations {
    return quotations.where((q) {
      final matchesSearch = (q['quotation_number'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          (q['customer']?['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());

      final rawStatus = (q['status'] ?? '').toString().toLowerCase();
      bool matchesStatus = true;
      if (selectedTab.value == 'Accepted') {
        matchesStatus = rawStatus == 'converted' || rawStatus == 'accepted';
      } else if (selectedTab.value == 'Pending') {
        matchesStatus = rawStatus == 'sent' ||
            rawStatus == 'draft' ||
            rawStatus == 'pending';
      } else if (selectedTab.value == 'Rejected') {
        matchesStatus = rawStatus == 'expired' || rawStatus == 'rejected';
      }

      bool matchesDate = true;
      if (dateRange.value != null && q['date'] != null) {
        final d = DateTime.parse(q['date']);
        matchesDate = d.isAfter(
                dateRange.value!.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchQuotations();
  }

  Future<void> fetchQuotations({bool forceRefresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/business/quotations';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (!forceRefresh && cachedData != null && cachedData is List) {
      quotations.value = List<Map<String, dynamic>>.from(cachedData);
      isLoading.value = false;
      return;
    }

    if (cachedData != null && cachedData is List) {
      quotations.value = List<Map<String, dynamic>>.from(cachedData);
    } else {
      isLoading.value = true;
    }

    try {
      final response = await ApiService.get('/business/quotations',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          quotations.value = jsonDecode(response.body);
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load quotations: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteQuotation(String quotationId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.delete(
          '/business/quotations/$quotationId',
          headers: {'x-user-id': userId});

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Quotation deletion scheduled offline. Will sync when online."
                : "Quotation deleted successfully",
            isError: false);
        quotations.removeWhere((q) => q['id'].toString() == quotationId);
        fetchQuotations(forceRefresh: true);
        if (Get.isRegistered<BusinessHomeController>()) {
          Get.find<BusinessHomeController>().fetchSummary();
        }
      } else {
        Utils.showSnackbar(
            "Error", "Failed to delete quotation: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to delete quotation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'converted':
      case 'accepted':
        return {
          'label': 'Accepted',
          'color': const Color(0xFF4CAF50),
          'bgColor': const Color(0xFFE8F5E9),
          'iconColor': const Color(0xFF4CAF50),
          'iconBgColor': const Color(0xFFE8F5E9),
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'expired':
      case 'rejected':
        return {
          'label': 'Rejected',
          'color': const Color(0xFFF44336),
          'bgColor': const Color(0xFFFFEBEE),
          'iconColor': const Color(0xFFF44336),
          'iconBgColor': const Color(0xFFFFCDD2).withValues(alpha: 0.5),
          'icon': Icons.cancel_outlined,
        };
      case 'sent':
      case 'draft':
      case 'pending':
      default:
        return {
          'label': status.toLowerCase() == 'draft' ? 'Draft' : 'Pending',
          'color': const Color(0xFFFF9800),
          'bgColor': const Color(0xFFFFF3E0),
          'iconColor': const Color(0xFF5F33E1),
          'iconBgColor': const Color(0xFFF3EFFF),
          'icon': Icons.description_rounded,
        };
    }
  }
}
