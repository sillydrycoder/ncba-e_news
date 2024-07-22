import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import '../app_screens/news_editor.dart';

class AdminTabSection extends StatefulWidget {
  const AdminTabSection({super.key});

  @override
  State<AdminTabSection> createState() => _AdminTabSectionState();
}

class _AdminTabSectionState extends State<AdminTabSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DocumentSnapshot> pendingNewsList = [];
  List<DocumentSnapshot> allNewsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getPendingNews();
    _getAllNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getPendingNews() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          .where('status', isEqualTo: 'pending')
          .get();
      setState(() {
        pendingNewsList = querySnapshot.docs;
      });
    } catch (e) {
      print("Error getting pending news: $e");
    }
  }

  Future<void> _getAllNews() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          .where('status', isEqualTo: 'published')
          .get();
      setState(() {
        allNewsList = querySnapshot.docs;
      });
    } catch (e) {
      print("Error getting all news: $e");
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
        return Uint8List(0); // Return an empty Uint8List if data is null
      }
    } catch (e) {
      print("Error getting image data: $e");
      return Uint8List(0); // Return an empty Uint8List in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending News'),
              Tab(text: 'Published News'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // First Tab: Pending News
                Center(
                  child: pendingNewsList.isEmpty
                      ? const Text('No pending news.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20.0,
                      ))
                      : ListView.builder(
                    itemCount: pendingNewsList.length,
                    itemBuilder: (context, index) {
                      String title = pendingNewsList[index]['title'] ?? 'Untitled';
                      String content = pendingNewsList[index]['content'] ?? '';
                      String thumbnailUrl = pendingNewsList[index]['thumbnailUrl'] ?? '';
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.yellow[100]
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: thumbnailUrl.isNotEmpty
                                  ? Image.network(thumbnailUrl)
                                  : const Icon(Icons.broken_image),
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
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    NewsEditor(
                                                        newsId: pendingNewsList[index].id)));
                                      },
                                      icon: const Icon(Icons.edit)),
                                  IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('Delete News'),
                                              content: const Text('Are you sure you want to delete this news?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    FirebaseFirestore.instance
                                                        .collection('news')
                                                        .doc(pendingNewsList[index].id)
                                                        .delete()
                                                        .then((value) => setState(() {
                                                      pendingNewsList.removeAt(index);
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
                                  IconButton(onPressed: () {
                                    FirebaseFirestore.instance.collection('news')
                                        .doc(pendingNewsList[index].id)
                                        .update({'status': 'published'})
                                        .then((value) {
                                      setState(() {
                                        pendingNewsList.removeAt(index);
                                      });
                                      _getAllNews();
                                    });
                                  }, icon: const Icon(Icons.done_all)),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Second Tab: All News
                Center(
                  child: allNewsList.isEmpty
                      ? const Text('No news published yet.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20.0,
                      ))
                      : ListView.builder(
                    itemCount: allNewsList.length,
                    itemBuilder: (context, index) {
                      String title = allNewsList[index]['title'] ?? 'Untitled';
                      String status = allNewsList[index]['status'].toString().toLowerCase();
                      String content = allNewsList[index]['content'] ?? '';
                      String thumbnailUrl = allNewsList[index]['thumbnailUrl'] ?? '';
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.green[100]
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: thumbnailUrl.isNotEmpty
                                  ? Image.network(thumbnailUrl)
                                  : const Icon(Icons.broken_image),
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
                                            arguments: {'newsId': allNewsList[index].id}
                                        );
                                      },
                                      icon: const Icon(Icons.edit)),
                                  IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('Delete News'),
                                              content: const Text('Are you sure you want to delete this news?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    FirebaseFirestore.instance
                                                        .collection('news')
                                                        .doc(allNewsList[index].id)
                                                        .delete()
                                                        .then((value) => setState(() {
                                                      allNewsList.removeAt(index);
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
                                  IconButton(onPressed: () {
                                    FirebaseFirestore.instance.collection('news')
                                        .doc(allNewsList[index].id)
                                        .update({'status': 'pending'})
                                        .then((value) {
                                      setState(() {
                                        allNewsList.removeAt(index);
                                      });
                                      _getPendingNews();
                                    });
                                  }, icon: const Icon(Icons.remove_done)),
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
        ],
      ),
    );
  }
}
