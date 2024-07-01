import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<DocumentSnapshot> newsList = [];

  @override
  void initState() {
    super.initState();
    _getAllNews();
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.feed), text: 'Your News'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(
              child: Text('Profile'),
            ),
            Center(
              child: newsList.isEmpty
                  ? const Text('No news uploaded yet.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20.0,
                      ))
                  : ListView.builder(
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        String title = newsList[index]['title'] ?? 'Untitled';
                        String status =
                            newsList[index]['status'].toString().toLowerCase();
                        String content = newsList[index]['content'] ?? '';
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
                                              context,
                                              '/edit_news',
                                              arguments: {'newsId': newsList[index].id}
                                          );                                        },
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
