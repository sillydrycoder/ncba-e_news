import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:ncba_news/available_catagories.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'news_editor.dart';

class PublishingPortal extends StatefulWidget {
  const PublishingPortal({super.key});

  @override
  _PublishingPortalState createState() => _PublishingPortalState();
}

class _PublishingPortalState extends State<PublishingPortal> {
  List<DocumentSnapshot> newsList = [];
  final RefreshController _refreshController =
  RefreshController(initialRefresh: false);


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
            .where('user.uid', isEqualTo: user.uid)
            .get();
        setState(() {
          newsList = querySnapshot.docs;
        });
      } else {
        print("No user is signed in.");
      }
    } catch (e) {
      print("Error getting news: $e");
    } finally {
      _refreshController.refreshCompleted();
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
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _getAllNews,
      child: newsList.isEmpty
              ? const Center(
                child: Text(
                            'No news uploaded yet.',
                            style: TextStyle(
                color: Colors.grey,
                fontSize: 20.0,
                            ),
                          ),
              )
              : ListView.builder(
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  String title = newsList[index]['title'] ?? 'Untitled';
                  String status = newsList[index]['status'].toString().toLowerCase();
                  String content = newsList[index]['content'] ?? '';
                  String thumbnailUrl = newsList[index]['thumbnailUrl'] ?? '';
                  String newsId = newsList[index].id;

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
                                      builder: (context) => NewsEditor(newsId: newsId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  // confirm delete
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete News'),
                                        content: const Text(
                                            'Are you sure you want to delete this news?'),
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
                                                  .doc(newsId)
                                                  .delete()
                                                  .then((value) =>
                                                  setState(() {
                                                    newsList.removeAt(index);
                                                  }));
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.delete),
                              ),
                              Expanded(child: Container()),
                              Text('Status: ${status.toUpperCase()}'),
                              const SizedBox(
                                width: 20.0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
