import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  String convertToPlainText(String json) {
    final doc = ParchmentDocument.fromJson(jsonDecode(json));
    return doc.toPlainText();
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
            final newsData = newsList[index].data() as Map<String, dynamic>;
            final title = newsData['title'] ?? 'Untitled';
            final content = newsData['content'];

            return Card(
              margin: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(title),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      convertToPlainText(content).replaceAll('\n', ' '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
