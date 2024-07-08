import 'package:cloud_firestore/cloud_firestore.dart';

getNews(String newsId) async {
  final newsDoc = await FirebaseFirestore.instance
      .collection('news')
      .doc(newsId)
      .get()
      .catchError((error) => error);
  return newsDoc;
}


