import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ncba_news/app.dart';
import 'package:parchment_delta/parchment_delta.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
    _initController(); // Initialize controller as before

    // If newsId is provided, load existing data
    if (widget.newsId != null) {
      _loadExistingNews();
    }
  }

  // Function to load existing news data
  Future<void> _loadExistingNews() async {
    try {
      final newsDoc = await FirebaseFirestore.instance.collection('news').doc(widget.newsId).get();
      if (newsDoc.exists) {
        final data = newsDoc.data() as Map<String, dynamic>;
        _titleController.text = data['title'];

        final heuristics = ParchmentHeuristics(
          formatRules: [],
          insertRules: [
            ForceNewlineForInsertsAroundInlineImageRule(),
          ],
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
      print("Error loading news: $e");
    }
  }



  @override
  void dispose() {
    super.dispose();
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
  }

  Future<void> _initController() async {
    try {
      final result = await rootBundle.loadString('welcome.json');
      final heuristics = ParchmentHeuristics(
        formatRules: [],
        insertRules: [
          ForceNewlineForInsertsAroundInlineImageRule(),
        ],
        deleteRules: [],
      ).merge(ParchmentHeuristics.fallback);
      final doc = ParchmentDocument.fromJson(
        jsonDecode(result),
        heuristics: heuristics,
      );
      _controller = FleatherController(document: doc);
    } catch (err, st) {
      if (kDebugMode) {
        print('Cannot read welcome.json: $err\n$st');
      }
      _controller = FleatherController();
    }
    setState(() {});
  }

  Future<void> _saveToFirestore(String status) async {
    print(1);
    final content = _controller!.document.toJson();
    await FirebaseFirestore.instance.collection('news').add(
      {
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'title': _titleController.text,
        'content': jsonEncode(content),
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
      },
    // ignore: body_might_complete_normally_catch_error
    ).catchError((error) {
      print(error);
    });
    print('saved to firebase');
  }

  Future<void> _showStatusDialog(String status) async {
    print(2);
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

  _saveAndShowDialog(String status, String message) async {
    if (widget.newsId != null) {
      // Update existing news if newsId is present
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.newsId)
          .update({
        'title': _titleController.text,
        'content': jsonEncode(_controller!.document.toJson()),
        'status': status, // Update the status if needed
        'timestamp': FieldValue.serverTimestamp(), // Optionally update the timestamp
      });
    } else {
      // Create new news if newsId is not present
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
              onPressed: () async {
                await _showBottomSheetPreview();
              },
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
               child: TextField(
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

/// This is an example insert rule that will insert a new line before and
/// after inline image embed.
class ForceNewlineForInsertsAroundInlineImageRule extends InsertRule {
  @override
  Delta? apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final cursorBeforeInlineEmbed = _isInlineImage(target.data);
    final cursorAfterInlineEmbed =
        previous != null && _isInlineImage(previous.data);

    if (cursorBeforeInlineEmbed || cursorAfterInlineEmbed) {
      final delta = Delta()..retain(index);
      if (cursorAfterInlineEmbed && !data.startsWith('\n')) {
        delta.insert('\n');
      }
      delta.insert(data);
      if (cursorBeforeInlineEmbed && !data.endsWith('\n')) {
        delta.insert('\n');
      }
      return delta;
    }
    return null;
  }

  bool _isInlineImage(Object data) {
    if (data is EmbeddableObject) {
      return data.type == 'image' && data.inline;
    }
    if (data is Map) {
      return data[EmbeddableObject.kTypeKey] == 'image' &&
          data[EmbeddableObject.kInlineKey];
    }
    return false;
  }
}
