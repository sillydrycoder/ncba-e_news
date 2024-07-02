
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ncba_news/app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


class AddNews extends StatefulWidget {
  final String? newsId; // Add this line to accept newsId

  const AddNews({super.key, this.newsId}); // Modify the constructor

  @override
  _AddNewsState createState() => _AddNewsState();
}

class _AddNewsState extends State<AddNews> {
  final FocusNode _focusNode = FocusNode();
  FleatherController? _controller;
  bool _saving = false;
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _thumbnail;
  String? _thumbnailUrl;
  String? thumbnailPath;



  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
    _initController(); // Initialize controller as before

    // If newsId is provided, load existing data
    if (widget.newsId != null) {
      _loadExistingNews();
    }

    _titleController.addListener(() {
      setState(() {}); // Update the UI when the title changes
    });
  }




  Future<void> _pickThumbnail() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnail = pickedFile; // Assign pickedFile directly to _thumbnail (which is of type XFile?)
      });
    }
  }




  // Function to load existing news data
  Future<void> _loadExistingNews() async {
    try {
      final newsDoc = await FirebaseFirestore.instance.collection('news').doc(widget.newsId).get();
      if (newsDoc.exists) {
        final data = newsDoc.data() as Map<String, dynamic>;
        _titleController.text = data['title'];
        _thumbnailUrl = data['thumbnailUrl'];

      final heuristics = const ParchmentHeuristics(
          formatRules: [],
          insertRules: [],
          deleteRules: [],
        ).merge(ParchmentHeuristics.fallback);

        final doc = ParchmentDocument.fromJson(
          jsonDecode(data['content']),
          heuristics: heuristics,
        );
        _controller = FleatherController(document: doc);
        setState(() {}); // Update the UI with loaded data
      }
    } catch (e) {
      // Handle errors if loading fails
      if (kDebugMode) {
        print("Error loading news: $e");
      }
    }
  }



  @override
  void dispose() {
    super.dispose();
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
  }

  Future<void> _initController() async {
    try {
      _controller = FleatherController();
    } catch (err, st) {
      if (kDebugMode) {
        print('Cannot read welcome.json: $err\n$st');
      }
      _controller = FleatherController();
    }
    setState(() {});
  }



  Future<void> _saveToFirestore(String status) async {
    String? thumbnailUrl;
    String? thumbnailPath;

    try {
      if (_thumbnail != null) {
        final bytes = await _thumbnail!.readAsBytes(); // Read bytes from File
        final ref = FirebaseStorage.instance
            .ref()
            .child('thumbnails')
            .child('${DateTime.now().toIso8601String()}.png');
        await ref.putData(bytes); // Upload bytes to Firebase Storage
        thumbnailPath = ref.fullPath;
        thumbnailUrl = await ref.getDownloadURL();
      }
    } catch (e) {
      print('Error uploading thumbnail: $e');
    }

    final content = _controller!.document.toJson();
    await FirebaseFirestore.instance.collection('news').add(
      {
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'userName': FirebaseAuth.instance.currentUser!.displayName,
        'title': _titleController.text,
        'content': jsonEncode(content),
        'thumbnailPath': thumbnailPath,
        'thumbnailUrl': thumbnailUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
      },
    ).catchError((error) {
      print(error);
    });

    print('Saved to Firestore');
  }


  Future<void> _showStatusDialog(String status) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Status'),
        content: Text('Your post is $status. You can see all your uploaded news in your profile settings. ${status == 'pending approval from admins' ? 'You can proceed further with thumbnail upload and news publish once you get an admin approval. Please be patient!' : ''} '),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage()));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndShowDialog(String status, String message) async {
    if (widget.newsId != null) {
      String? thumbnailUrl = _thumbnailUrl;
      if (_thumbnail != null) {
        final bytes = await _thumbnail!.readAsBytes(); // Convert to Uint8List
        final ref = FirebaseStorage.instance
            .ref()
            .child('thumbnails')
            .child('${DateTime.now().toIso8601String()}.png');
        await ref.putData(bytes); // Use putData for Uint8List
        thumbnailUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('news').doc(widget.newsId).update({
        'title': _titleController.text,
        'content': jsonEncode(_controller!.document.toJson()),
        'thumbnailUrl': thumbnailUrl,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await _saveToFirestore(status);
    }

    await _showStatusDialog(message);
    setState(() {
      _saving = false;
    });
  }

  _showBottomSheetPreview() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: const Text('Preview'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.done),
                    onPressed: () async {
                      setState(() {
                        _saving = true;
                      });
                      Navigator.of(context).pop();
                      await _saveAndShowDialog('pending', 'pending approval from admins');
                    },
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _titleController.text,
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    FleatherEditor(
                      controller: _controller!,
                      focusNode: _focusNode,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      onLaunchUrl: _launchUrl,
                      maxContentWidth: 800,
                      embedBuilder: _embedBuilder,
                      spellCheckConfiguration: SpellCheckConfiguration(
                        spellCheckService: DefaultSpellCheckService(),
                        misspelledSelectionColor: Colors.red,
                        misspelledTextStyle: DefaultTextStyle.of(context).style,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _saving = true;
        });
        await _saveAndShowDialog('draft', 'saved as draft');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Add News'),
          actions: [
            ElevatedButton(
              onPressed: (_titleController.text.isNotEmpty && (_thumbnail != null || _thumbnailUrl != null)) ? () async {
                await _showBottomSheetPreview();
              } : null,
              child: const Text('Done'),
            ),
            SizedBox(width: 20.0),
          ],
        ),
        body: _controller == null || _saving
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      hintText: 'Title',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickThumbnail,
                        child: const Text('Pick Thumbnail'),
                      ),
                      if (_thumbnail != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Image.network(_thumbnail!.path, width: 100, height: 100, fit: BoxFit.cover),
                        )
                      else if (_thumbnailUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Image.network(_thumbnailUrl!, width: 100, height: 100, fit: BoxFit.cover),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            FleatherToolbar.basic(controller: _controller!),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Expanded(
              child: FleatherEditor(
                controller: _controller!,
                focusNode: _focusNode,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                onLaunchUrl: _launchUrl,
                maxContentWidth: 800,
                embedBuilder: _embedBuilder,
                spellCheckConfiguration: SpellCheckConfiguration(
                    spellCheckService: DefaultSpellCheckService(),
                    misspelledSelectionColor: Colors.red,
                    misspelledTextStyle: DefaultTextStyle.of(context).style),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _embedBuilder(BuildContext context, EmbedNode node) {
    if (node.value.type == 'icon') {
      final data = node.value.data;

      const icons = {
        'home': Icons.home,
        'star': Icons.star,
        'person': Icons.person,
        'settings': Icons.settings,
        // Add more predefined icons as needed
      };

      final iconName = data['iconName'] ?? 'home'; // Default to 'home' if not specified
      final icon = icons[iconName] ?? Icons.home; // Use home icon if iconName is not found

      return Icon(
        icon,
        color: Color(int.parse(data['color'])),
        size: 18,
      );
    }
    return defaultFleatherEmbedBuilder(context, node);
  }


  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
  }
}
