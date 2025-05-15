import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/myuser.dart';
import 'dart:io';

// ignore: must_be_immutable
class UserInfoSection extends StatelessWidget {
  UserInfoSection({super.key, required this.myUser});
  final MyUser myUser;

  final ImagePicker _picker = ImagePicker();
  DateTime? newLastLogin;

  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      // Read the image as bytes
      List<int> imageBytes = await imageFile.readAsBytes();

      // Encode the image bytes to a Base64 string
      String base64Image = base64Encode(imageBytes);

      // Store the Base64 string in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUser.userId)
          .update({
        'profilePicture': base64Image,
      });

      print("Profile Picture uploaded successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime lastLoginDateTime = (myUser.lastLogin).toDate();
    String formattedDate =
        DateFormat('MMM dd yyyy HH:mm:ss').format(lastLoginDateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    myUser.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    'User ID: ${myUser.userId.substring(myUser.userId.length - 5).toUpperCase()}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.60,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      color: const Color.fromARGB(255, 232, 224, 199),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Center(
                        child: Text(
                          'Last Login: $formattedDate',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow[700],
                        ),
                      ),
                      Text(
                        myUser.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        title: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Select Profile Picture',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Get.back();
                                          },
                                          icon: Icon(Icons.close_rounded),
                                        ),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.camera_alt),
                                        title: Text('Capture from Camera'),
                                        onTap: () async {
                                          final XFile? image =
                                              await _picker.pickImage(
                                            source: ImageSource.camera,
                                            imageQuality:
                                                50, // Optional: Adjust image quality (0-100)
                                            preferredCameraDevice: CameraDevice
                                                .rear, // Use rear camera (can be front as well)
                                          );

                                          if (image != null) {
                                            // Convert the XFile to File
                                            File imageFile = File(image.path);

                                            // Call the method to upload the image and store URL in Firestore
                                            await uploadProfilePicture(
                                                imageFile);
                                          }
                                          Get.back(); // Close the modal bottom sheet
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.photo_library),
                                        title: Text('Select from Gallery'),
                                        onTap: () async {
                                          final XFile? image =
                                              await _picker.pickImage(
                                                  source: ImageSource.gallery);
                                          if (image != null) {
                                            File imageFile = File(image.path);
                                            await uploadProfilePicture(
                                                imageFile);
                                          }
                                          Get.back();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
