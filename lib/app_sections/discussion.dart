import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Discussion extends StatefulWidget {
  final String newsId;
  const Discussion({super.key, required this.newsId});

  @override
  _DiscussionState createState() => _DiscussionState();
}

class _DiscussionState extends State<Discussion> {
  List<QueryDocumentSnapshot> discussionList = [];
  late bool _loading = true;
  final TextEditingController _messageController = TextEditingController();
  late bool sending = false;

  @override
  void initState() {
    super.initState();
    _getNewsDiscussionCollection();
  }

  _getNewsDiscussionCollection() async {
    await FirebaseFirestore.instance
        .collection('news')
        .doc(widget.newsId)
        .collection('discussion')
        .orderBy('timestamp', descending: false) // Order by timestamp
        .get()
        .then((value) {
      setState(() {
        discussionList = value.docs;
        _loading = false;
      });
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateFormat timeFormat = DateFormat('h:mm a');

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today ${timeFormat.format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday ${timeFormat.format(date)}';
    } else {
      DateFormat dateFormat = DateFormat('dd MMM h:mm a');
      return dateFormat.format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      height: 400,
      child: Stack(
        children: [
          Center(
            child: _loading
                ? const CircularProgressIndicator()
                : discussionList.isEmpty
                ? const Text('No discussion yet.')
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Add padding to avoid being covered by text field
              itemCount: discussionList.length,
              itemBuilder: (context, index) {
                var discussion = discussionList[index].data() as Map<String, dynamic>;
                var timestamp = discussion['timestamp'] as Timestamp;
                var picture = discussion['user']['photoURL'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: discussion['user']['uid'] == FirebaseAuth.instance.currentUser?.uid
                ? Colors.greenAccent.shade400
                    : Colors.grey.shade400,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(discussion['comment'], style: const TextStyle(fontSize: 15),),
                      ),
                      Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: picture != ''
                              ? NetworkImage(picture)
                              : const AssetImage('assets/images/default_profile.jpg') as ImageProvider,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discussion['user']['uid'] == FirebaseAuth.instance.currentUser?.uid
                                  ? 'You'
                                  : discussion['user']['displayName'],
                            ),
                            Text(formatTimestamp(timestamp)),
                          ],
                        ),
                      ],
                    ),
                  ]
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TextField(
              controller: _messageController,
              enabled: !sending,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () async {
                    setState(() {
                      sending = true;
                    });
                    await FirebaseFirestore.instance
                        .collection('news')
                        .doc(widget.newsId)
                        .collection('discussion')
                        .add({
                      'comment': _messageController.text,
                      'user': {
                        'uid': FirebaseAuth.instance.currentUser?.uid,
                        'displayName': FirebaseAuth.instance.currentUser?.displayName,
                        'photoURL': FirebaseAuth.instance.currentUser?.photoURL ?? '',
                      },
                      'timestamp': FieldValue.serverTimestamp(),
                    }).then((value) {
                      setState(() {
                        _messageController.clear();
                        _getNewsDiscussionCollection();
                        sending = false;
                      });
                    });
                  },
                  icon: const Icon(Icons.send),
                ),
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
