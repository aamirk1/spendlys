import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/business_service.dart';
import 'package:spendly/app/utils/utils.dart';

class BusinessProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final gstController = TextEditingController();

  final accountNoController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  final selectedBank = Rxn<String>();
  final isLoading = false.obs;
  final logoUrl = Rxn<String>();
  final pickedLogo = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  final RxList<String> bankNames = <String>[].obs;
  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadBankNames();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.get(
        '/business/profile',
        headers: {'x-user-id': userId},
        useCache: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        nameController.text = data['name'] ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        gstController.text = data['gst_number'] ?? '';
        logoUrl.value = data['logo_url'];
        if (data != null &&
            data['name'] != null &&
            data['name'].toString().isNotEmpty) {
          Get.find<BusinessService>().setProfileCreated(true);
        }
        final gst = data != null ? data['gst_number']?.toString().trim() : null;
        Get.find<BusinessService>().setHasGstNumber(gst != null && gst.isNotEmpty);
        debugPrint("Fetched Profile: logo_url = ${logoUrl.value}");

        if (data['payment_details'] != null &&
            data['payment_details'].isNotEmpty) {
          final pd = data['payment_details'][0];
          selectedBank.value = pd['bank_name'];
          accountNoController.text = pd['account_number'] ?? '';
          ifscController.text = pd['ifsc'] ?? '';
          upiController.text = pd['upi_id'] ?? '';
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadBankNames() async {
    // 1. Try from local storage
    List<dynamic>? storedBanks = _storage.read<List<dynamic>>('bank_names');
    if (storedBanks != null && storedBanks.isNotEmpty) {
      bankNames.value = storedBanks.cast<String>();
    }

    // 2. Fetch from backend to sync
    try {
      final response = await ApiService.get('/business/banks');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<String> fetchedBanks = data.cast<String>();
        bankNames.value = fetchedBanks;

        // 3. Store in local storage
        _storage.write('bank_names', fetchedBanks);
      }
    } catch (e) {
      debugPrint("Error fetching bank names: $e");
      // If error and local storage is empty, use default (or empty)
      if (bankNames.isEmpty) {
        bankNames.value = ["Other"];
      }
    }
  }

  Future<void> pickLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      pickedLogo.value = File(image.path);
    }
  }

  Future<String?> _uploadLogo(String userId) async {
    if (pickedLogo.value == null) return logoUrl.value;

    try {
      final resp = await ApiService.postMultipart(
        '/business/profile/logo',
        pickedLogo.value!,
        'file',
        headers: {'x-user-id': userId},
      );

      final body = await resp.stream.bytesToString();
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(body);
        debugPrint("Upload Success: ${data['logo_url']}");
        return data['logo_url'];
      } else {
        debugPrint("Upload failed (Status: ${resp.statusCode}): $body");
        return logoUrl.value;
      }
    } catch (e) {
      debugPrint("Error uploading logo: $e");
      return logoUrl.value;
    }
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (selectedBank.value == null) {
      Utils.showSnackbar("Error", "Please select a Bank Name");
      return;
    }

    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) {
      Utils.showSnackbar("Error", "User not logged in");
      return;
    }

    isLoading.value = true;

    try {
      final Map<String, dynamic> payload = {
        "name": nameController.text.trim(),
        "address": addressController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "gst_number": gstController.text.trim(),
        "logo_url": await _uploadLogo(userId),
        "payment_details": [
          {
            "bank_name": selectedBank.value,
            "account_number": accountNoController.text.trim(),
            "ifsc": ifscController.text.trim(),
            "upi_id": upiController.text.trim(),
            "qr_code_url": null
          }
        ]
      };

      final response = await ApiService.post('/business/profile',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.find<BusinessService>().setProfileCreated(true);
        final gstStr = gstController.text.trim();
        Get.find<BusinessService>().setHasGstNumber(gstStr.isNotEmpty);
        Get.back();
        Utils.showSnackbar("Success", "Business Profile Updated",
            isError: false);
      } else {
        Utils.showSnackbar(
            "Error", "Failed to update profile: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    gstController.dispose();
    accountNoController.dispose();
    ifscController.dispose();
    upiController.dispose();
    super.onClose();
  }
}
