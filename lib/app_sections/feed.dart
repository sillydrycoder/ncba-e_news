import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fleather/fleather.dart'; // If you're using Fleather for rich text
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  List<DocumentSnapshot> newsList = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _getPublishedNews();
  }

  Future<void> _getPublishedNews() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          .where('status', isEqualTo: 'published')
          .get();
      setState(() {
        newsList = querySnapshot.docs;
      });
    } catch (e) {
      print("Error getting published news: $e");
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
    return Scaffold(
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _getPublishedNews, // Call the refresh function on swipe
        child: newsList.isEmpty
            ? const Center(
                child: Text(
                  'No published news yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 20.0),
                ),
              )
            : ListView.builder(
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final newsData =
                      newsList[index].data() as Map<String, dynamic>;
                  final title = newsData['title'] ?? 'Untitled';
                  final content = newsData['content'];
                  final thumbnailPath = newsData['thumbnailPath'] ?? null;

                  return Card(
                    margin: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumbnailPath == null
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
                              return const SizedBox(
                                width: double.infinity,
                                height: 150,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError ||
                                snapshot.data == null ||
                                snapshot.data!.isEmpty) {
                              print(snapshot.error);
                              print(snapshot.data);
                              return const Icon(Icons.error);
                            }
                            return ClipRRect(
                              // apply only to top
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                              child: Image.memory(
                                snapshot.data!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(title),
                          subtitle: Text(
                              "Author: ${newsData['userName'] ?? 'Unknown'}"),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Text(
                                convertToPlainText(content)
                                    .replaceAll('\n', ' '),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(child: Container()),
                              IconButton(
                                icon: const Icon(Icons.bookmark_border),
                                onPressed: () {
                                  print("Bookmark button pressed");
                                },
                              ),
                            ],
                          ),
                        ),
                        // Add more details (e.g., author, timestamp) as needed
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
