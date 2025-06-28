import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser!;
  String? _name;
  String? _photoURL;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .snapshots();

    // Listen to Firestore changes and update UI accordingly
    _userStream.listen((doc) async {
      await _user.reload(); // refresh user info from FirebaseAuth
      final refreshedUser = FirebaseAuth.instance.currentUser!;

      final data = doc.data();

      setState(() {
        _name = data?['name'] ?? refreshedUser.displayName ?? 'User';
        _photoURL = data?['photoURL'] ?? refreshedUser.photoURL;
      });
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage == null) return;

    final storageRef = FirebaseStorage.instance.ref().child(
      'profile_pics/${_user.uid}.jpg',
    );
    await storageRef.putFile(File(pickedImage.path));
    final imageUrl = await storageRef.getDownloadURL();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(_user.uid).set({
      'photoURL': imageUrl,
      'name': _name ?? _user.displayName ?? 'User',
    }, SetOptions(merge: true));

    // Update FirebaseAuth user profile photo URL
    await _user.updatePhotoURL(imageUrl);
    await _user.reload();

    setState(() {
      _photoURL = imageUrl;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initial = (_name != null && _name!.isNotEmpty)
        ? _name![0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Your Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.brown.shade200,
                backgroundImage: _photoURL != null
                    ? NetworkImage(_photoURL!)
                    : null,
                child: _photoURL == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _name ?? 'Loading...',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickAndUploadImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text(
                "Change Profile Picture",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
