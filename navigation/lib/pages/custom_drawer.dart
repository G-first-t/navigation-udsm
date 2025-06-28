import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:navigation/pages/profile_screen.dart';
import 'package:navigation/pages/help_feedback_screen.dart';
import 'package:navigation/auth/login_screen.dart';
import 'package:navigation/auth/auth_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String name = 'User';
  String? photoUrl;
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          name = data['name'] ?? refreshedUser.displayName ?? 'User';
          photoUrl = data['photoURL'] ?? refreshedUser.photoURL;
                });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: const Color(0xFFF8F1E4) ,
            child: UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(color:  Color(0xFFF8F1E4)),
              accountName: Text(
                name,
                style: const TextStyle(color: Colors.black87),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.black54),
              ),
              currentAccountPicture: photoUrl != null
                  ? CircleAvatar(backgroundImage: NetworkImage(photoUrl!))
                  : CircleAvatar(
                      backgroundColor: Colors.brown,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              onDetailsPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Placeholder
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Help & Feedback'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
