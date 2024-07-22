import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:intl/intl.dart';
import 'package:ncba_news/app_sections/discussion.dart';


class DisplayNews extends StatefulWidget {
  final String newsId;

  const DisplayNews({Key? key, required this.newsId}) : super(key: key);

  @override
  _DisplayNewsState createState() => _DisplayNewsState();
}

class _DisplayNewsState extends State<DisplayNews> {
  FleatherController? _controller;
  bool _isLoading = true;
  late String _thumbnailUrl = '';
  late String _title = '';
  late Timestamp _date;
  late var _userName;
  late String _profilePicture = '';
  late bool saved = false;
  late String category;

  @override
  void initState() {
    super.initState();
    _loadNewsContent();
  }

  Future<void> _loadNewsContent() async {
    final doc = await FirebaseFirestore.instance
        .collection('news')
        .doc(widget.newsId)
        .get();

    if (doc.exists) {
      print(doc.data);
      final contentJson = doc['content'];
      final document = ParchmentDocument.fromJson(jsonDecode(contentJson));
      _controller = FleatherController(document: document);
      _thumbnailUrl = doc['thumbnailUrl'];
      _title = doc['title'];
      _date = doc['createdAt'];
      _userName = doc['user']['displayName'];
      _profilePicture = doc['user']['photoURL'];
      saved = doc['savedBy'].contains(FirebaseAuth.instance.currentUser?.uid);
      category = doc['category'];

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News Details"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: _profilePicture != ''
                                ? NetworkImage(_profilePicture)
                                : const AssetImage(
                                    'assets/images/default_profile.jpg'),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              _userName ?? 'Unknown',
                            ),
                          ),
                          IconButton(
                            icon: saved
                                ? const Icon(
                                    Icons.bookmark,
                                    color: Colors.blue,
                                  )
                                : const Icon(Icons.bookmark_border),
                            onPressed: () async {
                              saved
                                  ? await FirebaseFirestore.instance
                                      .collection('news')
                                      .doc(widget.newsId)
                                      .update({
                                      'savedBy': FieldValue.arrayRemove([
                                        FirebaseAuth.instance.currentUser?.uid
                                      ])
                                    })
                                  : await FirebaseFirestore.instance
                                      .collection('news')
                                      .doc(widget.newsId)
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
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          Text(
                            DateFormat('d MMM yyyy h:mm a').format((_date.toDate()).toLocal()),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Card(
                        elevation: 5,
                        child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10.0)),
                            child: Image.network(_thumbnailUrl))),
                    Divider(),
                    FleatherEditor(
                      controller: _controller!,
                      readOnly: true,
                      embedBuilder: _embedBuilder,
                    ),
                    Discussion(newsId: widget.newsId),
                  ],
                ),
              ),
            ),
    );
  }
}

Widget _embedBuilder(BuildContext context, EmbedNode node) {
  if (node.value.type == 'icon') {
    final data = node.value.data;
    // Icons.rocket_launch_outlined
    return Icon(
      IconData(int.parse(data['codePoint']), fontFamily: data['fontFamily']),
      color: Color(int.parse(data['color'])),
      size: 18,
    );
  }

  if (node.value.type == 'image') {
    final sourceType = node.value.data['source_type'];
    ImageProvider? image;
    if (sourceType == 'assets') {
      image = AssetImage(node.value.data['source']);
    } else if (sourceType == 'file') {
      image = FileImage(File(node.value.data['source']));
    } else if (sourceType == 'url') {
      image = NetworkImage(node.value.data['source']);
    }
    if (image != null) {
      return Padding(
        // Caret takes 2 pixels, hence not symmetric padding values.
        padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
      );
    }
  }

  return defaultFleatherEmbedBuilder(context, node);
}
