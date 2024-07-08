import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<DocumentSnapshot> newsList = [];
  late bool _editing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late bool _verified = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _profilePic;

  _setInitialValues() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _verified = user.emailVerified;
    }
  }

  @override
  void initState() {
    super.initState();
    _getAllNews();
    _setInitialValues();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePic =
            pickedFile; // Assign pickedFile directly to _thumbnail (which is of type XFile?)
      });
    }
  }

  Future<void> _getAllNews() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('news')
            .where('userId', isEqualTo: user.uid)
            .get();
        setState(() {
          newsList = querySnapshot.docs;
        });
      } else {
        print("No user is signed in.");
      }
    } catch (e) {
      print("Error getting news: $e");
    }
  }

  String truncateString(String content, int maxLength) {
    if (content.length <= maxLength) {
      return content;
    }
    return "${content.substring(0, maxLength).replaceAll('\n', ' ')}...";
  }

  String convertToPlainText(String json) {
    final doc = ParchmentDocument.fromJson(jsonDecode(json));
    return truncateString(doc.toPlainText(), 200);
  }

  Future<Uint8List> getImageData(String path) async {
    try {
      print("Path: $path");
      Uint8List? data = await FirebaseStorage.instance.ref(path).getData();
      if (data != null) {
        return data;
      } else {
        // Return an empty Uint8List if data is null
        return Uint8List(0);
      }
    } catch (e) {
      print("Error getting image data: $e");
      // Return an empty Uint8List in case of an error
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: const TabBar(
            indicatorColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.feed), text: 'Your News'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(
                child: SingleChildScrollView(
              child: Stack(alignment: Alignment.center, children: [
                Card(
                  margin: const EdgeInsets.all(12.0),
                  elevation: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    width: 300,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  if (_editing) {
                                    _pickImage;
                                  }
                                },
                                // disabled if not editing
                                icon: _editing
                                    ? const Icon(
                                        Icons.add_photo_alternate_outlined)
                                    : const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.grey)),
                            const SizedBox(width: 20),
                            const CircleAvatar(
                              radius: 50,
                              child: Icon(Icons.account_circle_outlined,
                                  size: 100),
                            ),
                            const SizedBox(width: 20),
                            _verified
                                ? const Icon(Icons.verified,
                                    color: Colors.green, size: 30)
                                : IconButton(
                                    onPressed: () {
                                      try {
                                        FirebaseAuth.instance.currentUser!
                                            .sendEmailVerification()
                                            .then((value) =>
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                  content: Text(
                                                      'Verification email sent.'),
                                                  duration:
                                                      Duration(seconds: 5),
                                                )));
                                        print(1);
                                        print(FirebaseAuth
                                            .instance.currentUser!.uid);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Error sending verification email: $e'),
                                          duration: const Duration(seconds: 5),
                                        ));
                                        print(2);
                                      }
                                    },
                                    icon: const Icon(Icons.mark_email_unread,
                                        color: Colors.red, size: 30),
                                  ),
                          ],
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
                        TextField(
                          controller: _phoneController,
                          enabled: _editing,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            hintText: 'Enter your phone number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  // top right corner
                  top: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _editing = !_editing;
                        });
                      },
                      icon: _editing
                          ? const Icon(Icons.save)
                          : const Icon(Icons.edit),
                    ),
                  ),
                ),
              ]),
            )),
            Center(
              child: newsList.isEmpty
                  ? const Text(
                      'No news uploaded yet.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20.0,
                      ),
                    )
                  : ListView.builder(
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        String title = newsList[index]['title'] ?? 'Untitled';
                        String status =
                            newsList[index]['status'].toString().toLowerCase();
                        String content = newsList[index]['content'] ?? '';
                        String thumbnailPath =
                            newsList[index]['thumbnailPath'] ?? null;
                        return Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: status == 'published'
                                ? Colors.green[100]
                                : status == 'pending'
                                    ? Colors.yellow[100]
                                    : Colors.red[100],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: thumbnailPath == null
                                    ? const SizedBox(
                                  width: double.infinity,
                                  height: 150,
                                  child: Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey, size: 150,)
                                  ),
                                )
                                    :
                                FutureBuilder<Uint8List>(
                                  future: getImageData(thumbnailPath),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator(
                                        color: Colors.grey,
                                      );
                                    }
                                    if (snapshot.hasError ||
                                        snapshot.data == null ||
                                        snapshot.data!.isEmpty) {
                                      print(snapshot.error);
                                      print(snapshot.data);
                                      return const Icon(Icons.error);
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 100,
                                    );
                                  },
                                ),
                                title: Text(title),
                                subtitle: Text(convertToPlainText(content)),
                              ),
                              const Divider(
                                thickness: 0.2,
                                indent: 20.0,
                                endIndent: 20.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                              context, '/edit_news',
                                              arguments: {
                                                'newsId': newsList[index].id
                                              });
                                        },
                                        icon: const Icon(Icons.edit)),
                                    IconButton(
                                        onPressed: () {
                                          // confirm delete
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    const Text('Delete News'),
                                                content: const Text(
                                                    'Are you sure you want to delete this news?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      FirebaseFirestore.instance
                                                          .collection('news')
                                                          .doc(newsList[index]
                                                              .id)
                                                          .delete()
                                                          .then((value) =>
                                                              setState(() {
                                                                newsList
                                                                    .removeAt(
                                                                        index);
                                                              }));
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.delete)),
                                    Expanded(child: Container()),
                                    Text('Status: ${status.toUpperCase()}'),
                                    const SizedBox(
                                      width: 20.0,
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
