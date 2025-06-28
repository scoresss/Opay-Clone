import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String? profileUrl;
  bool loading = false;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = data['name'] ?? '';
        email = data['email'] ?? '';
        profileUrl = data['profile'] ?? null;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked == null) return;

    setState(() => loading = true);

    final storageRef = FirebaseStorage.instance.ref().child('profile_pics/$uid.jpg');
    await storageRef.putFile(File(picked.path));
    final url = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({'profile': url});
    setState(() {
      profileUrl = url;
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.green),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileUrl != null ? NetworkImage(profileUrl!) : null,
                  child: profileUrl == null ? const Icon(Icons.person, size: 60) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: loading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Center(child: Text(email, style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
    );
  }
}
