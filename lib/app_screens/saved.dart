import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Saved extends StatefulWidget {
  const Saved({super.key});

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  List<DocumentSnapshot> newsList = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);


  @override
  void initState() {
    super.initState();
    _getSavedNews();
    print(newsList);
  }

  Future<void> _getSavedNews() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          .where('savedBy',
              arrayContains: FirebaseAuth.instance.currentUser!.uid)
          .get();
      setState(() {
        newsList = querySnapshot.docs;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error getting published news: $e");
      }
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
      onRefresh: _getSavedNews,
      child: newsList.isEmpty
          ? const Center(
              child: Text(
                'No saved news yet.',
                style: TextStyle(color: Colors.grey, fontSize: 20.0),
              ),
            )
          : ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final newsData = newsList[index].data() as Map<String, dynamic>;
                final title = newsData['title'] ?? 'Untitled';
                final content = newsData['content'];
                final thumbnailUrl = newsData['thumbnailUrl'];
                final saved = newsData['savedBy']
                    .contains(FirebaseAuth.instance.currentUser?.uid);

                return Card(
                  margin: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 150,
                        child: thumbnailUrl == null
                            ? Container(
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 150,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                child: Image.network(
                                  thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                      size: 150,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      ListTile(
                        title: Text(title),
                        subtitle: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: newsData['user']['photoURL'] !=
                                      ''
                                  ? NetworkImage(newsData['user']['photoURL'])
                                  : const AssetImage(
                                      'assets/images/default_profile.jpg'),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                newsData['user']['displayName'] ?? 'Unknown',
                              ),
                            ),
                            IconButton(
                              icon: saved
                                  ? const Icon(
                                      Icons.bookmark,
                                      color: Colors.blue,
                                    )
                                  : Icon(Icons.bookmark_border),
                              onPressed: () async {
                                saved
                                    ? await FirebaseFirestore.instance
                                        .collection('news')
                                        .doc(newsList[index].id)
                                        .update({
                                        'savedBy': FieldValue.arrayRemove([
                                          FirebaseAuth.instance.currentUser?.uid
                                        ])
                                      })
                                    : await FirebaseFirestore.instance
                                        .collection('news')
                                        .doc(newsList[index].id)
                                        .update({
                                        'savedBy': FieldValue.arrayUnion([
                                          FirebaseAuth.instance.currentUser?.uid
                                        ])
                                      });
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          convertToPlainText(content).replaceAll('\n', ' '),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
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
