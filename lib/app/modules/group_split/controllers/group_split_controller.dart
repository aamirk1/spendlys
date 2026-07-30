import 'dart:convert';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/models/group_split_model.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:uuid/uuid.dart';

class GroupSplitController extends GetxController {
  var groupSplits = <GroupSplit>[].obs;
  var isLoading = false.obs;
  var errorMsg = Rx<String?>(null);

  @override
  void onInit() {
    fetchGroupSplits();
    super.onInit();
  }

  Future<void> fetchGroupSplits({bool forceRefresh = false}) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/group-splits/?user_id=$userId';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (!forceRefresh && cachedData != null && cachedData is List) {
      _parseAndSetGroupSplits(cachedData);
      return;
    }

    if (cachedData != null && cachedData is List) {
      _parseAndSetGroupSplits(cachedData);
    } else {
      isLoading.value = true;
    }

    try {
      final response = await ApiService.get('/group-splits/?user_id=$userId');
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          _parseAndSetGroupSplits(data);
        }
      } else {
        errorMsg.value = 'Failed to fetch group splits: ${response.body}';
      }
    } catch (e) {
      errorMsg.value = 'Error fetching group splits: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _parseAndSetGroupSplits(List<dynamic> data) {
    final fetchedSplits = (data).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id']?.toString() ?? '';
      return GroupSplit.fromMap(map, id);
    }).toList();

    fetchedSplits.sort((a, b) => b.date.compareTo(a.date));
    groupSplits.value = fetchedSplits;
    errorMsg.value = null;
  }

  Future<void> addGroupSplit(GroupSplit split) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) {
      Utils.showSnackbar('Error', 'User not logged in', isError: true);
      return;
    }

    isLoading.value = true;
    try {
      final uuid = const Uuid().v4();
      split.id = uuid;
      split.userId = userId;

      final body = split.toMap();
      final response =
          await ApiService.post('/group-splits/?user_id=$userId', body: body);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
          isOffline ? 'Offline' : 'Success',
          isOffline
              ? 'Group split saved offline. Will sync when online.'
              : 'Group split created successfully!',
          isError: false,
        );
        fetchGroupSplits(forceRefresh: true);
        Get.back();
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to save group split: ${response.body}',
            isError: true);
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Error creating group split: $e',
          isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateGroupSplit(GroupSplit split) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final body = split.toMap();
      final response = await ApiService.put(
          '/group-splits/${split.id}?user_id=$userId',
          body: body);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
          isOffline ? 'Offline' : 'Success',
          isOffline
              ? 'Update saved offline. Will sync when online.'
              : 'Group split updated successfully!',
          isError: false,
        );
        fetchGroupSplits(forceRefresh: true);
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update group split: ${response.body}',
            isError: true);
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Error updating group split: $e',
          isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteGroupSplit(String id) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response =
          await ApiService.delete('/group-splits/$id?user_id=$userId');
      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
          isOffline ? 'Offline' : 'Success',
          isOffline
              ? 'Deletion queued offline.'
              : 'Group split deleted successfully!',
          isError: false,
        );
        fetchGroupSplits(forceRefresh: true);
        Get.back(); // Back from detail screen
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to delete group split: ${response.body}',
            isError: true);
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Error deleting group split: $e',
          isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
