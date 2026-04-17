import 'dart:convert';
import 'package:spendly/res/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:spendly/services/business_service.dart';

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        nameController.text = data['name'] ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        gstController.text = data['gst_number'] ?? '';
        logoUrl.value = data['logo_url'];
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

class BusinessProfileView extends StatelessWidget {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: SafeArea(
          child: Obx(() => Stack(
                children: [
                  Form(
                    key: controller.formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: AnimationLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 600),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 60.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: controller.pickLogo,
                                  child: Obx(() => Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.blue.withOpacity(0.1),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            )
                                          ],
                                          image: controller.pickedLogo.value !=
                                                  null
                                              ? DecorationImage(
                                                  image: FileImage(controller
                                                      .pickedLogo.value!),
                                                  fit: BoxFit.cover,
                                                )
                                              : (controller.logoUrl.value !=
                                                      null
                                                  ? DecorationImage(
                                                      image: NetworkImage(() {
                                                        String url = controller.logoUrl.value!;
                                                        if (!url.startsWith('http')) {
                                                          url = "https://dailybachatapi.serwex.in$url";
                                                        }
                                                        String connector = url.contains('?') ? '&' : '?';
                                                        return "$url${connector}t=${DateTime.now().millisecondsSinceEpoch}";
                                                      }()),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null),
                                        ),
                                        child: controller.pickedLogo.value ==
                                                    null &&
                                                controller.logoUrl.value == null
                                            ? const Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 40,
                                                color: Colors.blueAccent)
                                            : null,
                                      )),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  "Business Logo (Optional)",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSectionTitle("General Information"),
                              _buildCard(
                                children: [
                                  _buildTextField(
                                    controller: controller.nameController,
                                    label: "Business Name",
                                    icon: Icons.store_rounded,
                                    validator: (v) => Validators.requiredField(
                                        v, "Business Name"),
                                  ),
                                  _buildTextField(
                                    controller: controller.addressController,
                                    label: "Address",
                                    icon: Icons.location_on_rounded,
                                    maxLines: 3,
                                    validator: (v) =>
                                        Validators.requiredField(v, "Address"),
                                  ),
                                  _buildTextField(
                                    controller: controller.phoneController,
                                    label: "Phone",
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    validator: Validators.mobileValidator,
                                  ),
                                  _buildTextField(
                                    controller: controller.emailController,
                                    label: "Email",
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: Validators.emailValidator,
                                  ),
                                  _buildTextField(
                                    controller: controller.gstController,
                                    label: "GST Number (Optional)",
                                    icon: Icons.receipt_long_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              _buildSectionTitle("Payment Details"),
                              _buildCard(
                                children: [
                                  _buildTextField(
                                    controller: controller.upiController,
                                    label: "UPI ID",
                                    icon: Icons.qr_code_rounded,
                                    validator: (v) =>
                                        Validators.requiredField(v, "UPI ID"),
                                  ),
                                  _buildDropdownField(controller),
                                  _buildTextField(
                                    controller: controller.accountNoController,
                                    label: "Account Number",
                                    icon: Icons.account_balance_wallet_rounded,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    validator:
                                        Validators.accountNumberValidator,
                                  ),
                                  _buildTextField(
                                    controller: controller.ifscController,
                                    label: "IFSC Code",
                                    icon: Icons.account_balance_rounded,
                                    inputFormatters: [UpperCaseTextFormatter()],
                                    validator: Validators.ifscValidator,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 35),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    elevation: 8,
                                    shadowColor:
                                        Colors.blueAccent.withOpacity(0.4),
                                  ),
                                  child: const Text(
                                    "SAVE PROFILE",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (controller.isLoading.value)
                    Container(
                      color: Colors.white.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),
                    ),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.blueAccent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDropdownField(BusinessProfileController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Obx(() => DropdownButtonFormField<String>(
            initialValue: controller.selectedBank.value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Bank Name",
              prefixIcon:
                  const Icon(Icons.account_balance, color: Colors.blueAccent),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
              ),
            ),
            items: controller.bankNames.map((bank) {
              return DropdownMenuItem(
                value: bank,
                child: Text(bank, style: const TextStyle(fontSize: 15)),
              );
            }).toList(),
            onChanged: (value) {
              controller.selectedBank.value = value;
            },
            validator: (value) =>
                value == null ? 'Bank Name is required' : null,
          )),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        cursorColor: Colors.blueAccent,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              maxLines == 1 ? Icon(icon, color: Colors.blueAccent) : null,
          alignLabelWithHint: maxLines > 1,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
