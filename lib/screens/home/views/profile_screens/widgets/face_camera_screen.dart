import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProfileImageCapture extends StatefulWidget {
  @override
  _ProfileImageCaptureState createState() => _ProfileImageCaptureState();
}

class _ProfileImageCaptureState extends State<ProfileImageCapture> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _cropImage(File(pickedFile.path));
    }
  }

  // Method to crop the picked image
  Future<void> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      // Rectangle crop style removed as 'cropStyle' is not a valid parameter
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Square aspect ratio
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, // Lock aspect ratio to square
        ),
        // IOSUiSettings(
        //   minimumAspectRatio: 1.0,
        //   resetButtonHidden: true,
        //   showCancelControl: true,
        // ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }

  // Method to upload image to Firebase Storage and update Firestore
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null) return;

      // Upload image to Firebase Storage
      String filePath = 'profile_pictures/${user.uid}.jpg';
      UploadTask uploadTask =
          FirebaseStorage.instance.ref(filePath).putFile(_imageFile!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore with the image URL
      await _firestore.collection('users').doc(user.uid).update({
        'profilePicUrl': downloadUrl,
        'lastProfileUpdate': FieldValue.serverTimestamp(),
      });

      // Show a success message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capture and Edit Profile Pic')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the selected/cropped image
            _imageFile == null
                ? Icon(Icons.camera_alt, size: 100, color: Colors.grey)
                : Image.file(_imageFile!,
                    height: 200, width: 200, fit: BoxFit.cover),

            // Pick Image Button
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),

            // Upload Image Button
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Save Image'),
            ),
          ],
        ),
      ),
    );
  }
}
