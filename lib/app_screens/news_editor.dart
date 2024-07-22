import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_stepper_reloaded/cool_stepper_reloaded.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:fleather/fleather.dart';
import 'package:flutter/painting.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parchment_delta/parchment_delta.dart';
import 'package:url_launcher/url_launcher.dart';

import '../available_catagories.dart';

class NewsEditor extends StatefulWidget {
  final String? newsId;

  const NewsEditor({super.key, this.newsId});

  @override
  _NewsEditorState createState() => _NewsEditorState();
}

class _NewsEditorState extends State<NewsEditor> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  NewsCategory? _selectedCategory; // Add this line

  final FocusNode _focusNode = FocusNode();
  FleatherController? _controller;
  CroppedFile? _croppedFile;
  late var _documentId = null;
  late var _thumbnailUrl = '';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
    _initController();

    if (widget.newsId != null) {
      _documentId = widget.newsId;
      _getDocument();
    }
  }

  _getDocument() async {
    if (_documentId != null) {
      await FirebaseFirestore.instance
          .collection('news')
          .doc(_documentId)
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _titleCtrl.text = doc['title'];
            _controller = FleatherController(
                document:
                    ParchmentDocument.fromJson(jsonDecode(doc['content'])));
            _thumbnailUrl = doc['thumbnailUrl'];
            _selectedCategory  = NewsCategory.values.firstWhere((element) => element.name == doc['category']);
          });
          print(_thumbnailUrl);
        }
      });
    }
  }

  Future<void> _initController() async {
    try {
      final placeholderArticle =
          await rootBundle.loadString('assets/welcome.json');
      final heuristics = ParchmentHeuristics(
        formatRules: [],
        insertRules: [
          ForceNewlineForInsertsAroundInlineImageRule(),
        ],
        deleteRules: [],
      ).merge(ParchmentHeuristics.fallback);
      final doc = ParchmentDocument.fromJson(
        jsonDecode(placeholderArticle),
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

  @override
  void dispose() {
    super.dispose();
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
  }

  Future<void> _cropImage(image) async {
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.ratio16x9]),
          IOSUiSettings(
            title: 'Cropper',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 520,
              height: 520,
            ),
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      CoolStep(
        alignment: Alignment.center,
        content: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please provide your news/article Title and Category:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'News Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                controller: _titleCtrl,
              ),
              const SizedBox(height: 10),
              // Category selection
              DropdownButtonFormField<NewsCategory>(
                value: _selectedCategory,
                items: NewsCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        validation: () {
          if (!_formKey.currentState!.validate()) {
            return 'Fill form correctly';
          } else if (_documentId == null) {
            //   initialize a news document on firebase firestore:
            FirebaseFirestore.instance.collection('news').add({
              'title': _titleCtrl.text,
              'user': {
                'uid': FirebaseAuth.instance.currentUser!.uid,
                'displayName':
                    FirebaseAuth.instance.currentUser!.displayName ?? 'Unknown',
                'email': FirebaseAuth.instance.currentUser!.email,
                'photoURL': FirebaseAuth.instance.currentUser!.photoURL ?? ''
              },
              'enrolledBy': [],
              'status': 'draft',
              'savedBy': [],
              'thumbnailUrl': '',
              'category': _selectedCategory!.name,
              'content': [],
              'createdAt': FieldValue.serverTimestamp(),
            }).then(
              (value) {
                setState(() {
                  _documentId = value.id;
                });
              },
            );
            return null;
          }
          return null;
        },
      ),
      CoolStep(
        content: _controller == null
            ? const CircularProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Write your article below in rich text.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  FleatherToolbar.basic(
                    controller: _controller!,
                    leading: [
                      IconButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            // Generate a unique file name for the image
                            final fileName = List.generate(
                              128,
                              (index) =>
                                  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
                                      .split('')[Random().nextInt(62)],
                            ).join();

                            // Upload the image to Firebase Storage
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child('images/$fileName');
                            final uploadTask =
                                storageRef.putFile(File(image.path));
                            final snapshot = await uploadTask;
                            final downloadURL =
                                await snapshot.ref.getDownloadURL();

                            // Get the current selection in the editor
                            final selection = _controller!.selection;

                            // Embed the image in the document using the download URL
                            _controller!.replaceText(
                              selection.baseOffset,
                              selection.extentOffset - selection.baseOffset,
                              EmbeddableObject('image', inline: false, data: {
                                'source_type': 'url',
                                'source': downloadURL,
                              }),
                            );

                            // Add a newline after the image
                            _controller!.replaceText(
                              selection.baseOffset + 1,
                              0,
                              '\n',
                              selection: TextSelection.collapsed(
                                  offset: selection.baseOffset + 2),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        color: Colors.black,
                        iconSize: 20,
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.grey.shade400,
                        indent: 15,
                        endIndent: 15,
                      ),
                    ],
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  FleatherEditor(
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
                        misspelledTextStyle:
                            DefaultTextStyle.of(context).style),
                  ),
                ],
              ),
        validation: () {
          if (_controller!.document == {}) {
            return 'Content is required';
          } else {
            // update the news document on firebase firestore:
            FirebaseFirestore.instance
                .collection('news')
                .doc(_documentId)
                .update({
              'content': jsonEncode(_controller!.document.toJson()),
            });
            return null;
          }
        },
      ),
      CoolStep(
          content: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _croppedFile != null || _thumbnailUrl != ''
                ? Stack(
                    children: [
                      _thumbnailUrl != ''
                          ? Image.network(
                              _thumbnailUrl,
                              fit: BoxFit.fill,
                            )
                          : Image.file(
                              File(_croppedFile!.path),
                              fit: BoxFit.fill,
                            ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.outlined(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(Colors.white),
                          ),
                          highlightColor: Colors.black,
                          onPressed: () {
                            setState(() {
                              _croppedFile = null;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        await _cropImage(image);
                      }
                    },
                    label: const Text('Select a Thumbnail'),
                    icon: const Icon(Icons.crop),
                  ),
          ),
          validation: () {
            FirebaseFirestore.instance
                .collection('news')
                .doc(_documentId)
                .update({'status': 'pending'});
            if (_croppedFile == null) {
              if (_thumbnailUrl == '') {
                return 'Thumbnail is required';
              }
              return null;
            } else {
              // Upload the thumbnail to Firebase Storage
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('thumbnails/$_documentId');
              final uploadTask = storageRef.putFile(File(_croppedFile!.path));
              uploadTask.whenComplete(() async {
                final downloadURL = await storageRef.getDownloadURL();
                // Update the news document on Firebase Firestore
                FirebaseFirestore.instance
                    .collection('news')
                    .doc(_documentId)
                    .update({'thumbnailUrl': downloadURL});
              });
              return null;
            }
          },
          alignment: Alignment.center),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add News"),
      ),
      body: CoolStepper(
        isHeaderEnabled: false,
        hasRoundedCorner: false,
        contentPadding: const EdgeInsets.all(16.0),
        config: CoolStepperConfig(
          finishButton:
              TextButton(onPressed: () {}, child: const Text("Finish")),
          nextButton: TextButton(onPressed: () {}, child: const Text("Next")),
          backButton: TextButton(onPressed: () {}, child: const Text("Back")),
          stepColor: Colors.white,
          headerColor: Colors.white54,
        ),
        onCompleted: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content:_documentId !=null ? const Text('Article Updated') : const Text('Article Submitted')));
          Navigator.of(context).pop();
        },
        steps: steps,
      ),
    );
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

  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final _canLaunch = await canLaunchUrl(uri);
    if (_canLaunch) {
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
