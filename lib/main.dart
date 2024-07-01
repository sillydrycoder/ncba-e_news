import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ncba_news/app_screens/authenticate.dart';

import 'app.dart';
import 'app_screens/add_news.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// In your main.dart or a separate routes file
Map<String, WidgetBuilder> routes = {
  '/add_news': (context) => const AddNews(),
  '/edit_news': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    return AddNews(newsId: args?['newsId']);
  },
};

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;

  @override
  void initState() {
    super.initState();
    // Listen for authentication changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user; // Update the user state variable
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: routes,
      debugShowCheckedModeBanner: false,
      title: 'NCBA News',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: _user == null ? const Authenticate() : const MyHomePage(),
    );
  }
}
