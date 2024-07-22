import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _editing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _verified = false;
  final ImagePicker _picker = ImagePicker();
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _setInitialValues();
  }

  void _setInitialValues() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _verified = user.emailVerified;
      setState(() {
        _profileImage = user.photoURL;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Handle image upload here and get the URL
      // Example:
      // String imageUrl = await uploadImageToFirebase(pickedFile);
      // setState(() {
      //   _profileImage = imageUrl;
      // });

      setState(() {
        _profileImage = pickedFile.path; // Temporary local path, replace with uploaded URL
      });
    }
  }

  Future<void> _updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
        return;
      }
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email cannot be empty')));
        return;
      }
      if (user.displayName != _nameController.text) {
        await user.updateDisplayName(_nameController.text).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated')));
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating name')));
        });
      }
      if (user.email != _emailController.text ) {
        await user.verifyBeforeUpdateEmail(_emailController.text).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated')));
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating email')));
        });
      }
      _setInitialValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 4)),
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      maxRadius: 75,
                      backgroundImage: _profileImage == null
                          ? const AssetImage('assets/images/default_profile.jpg')
                          : NetworkImage(_profileImage!) as ImageProvider,
                      backgroundColor: Colors.transparent,
                    ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.black),
                          ),
                          color: Colors.white,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          onPressed: _pickImage,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                enabled: _editing,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                enabled: _editing,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () async {
                  if (_editing) {
                    _updateProfile();
                  }
                  setState(() {
                    _editing = !_editing;
                  });
                },
                child: Text(_editing ? 'Save' : 'Edit'),
              ),
              const SizedBox(height: 20),
              const Text('Note: The name and profile photo will be displayed publicly on your articles.', style: TextStyle(fontWeight: FontWeight.w700),)
            ],
          ),
        ),
      ),
    );
  }
}
