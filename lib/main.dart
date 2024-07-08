import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:ncba_news/app_sections/signin.dart';

import 'app.dart';
import 'app_screens/add_news.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // configure app check
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.playIntegrity, webProvider: ReCaptchaEnterpriseProvider("6LeXYQgqAAAAAHdCNX4kcl7i2Az9oowOLK7WPvV-"));
  final themeStr = await rootBundle.loadString('assets/theme.json');
  final themeJSON = jsonDecode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJSON);
  runApp(MyApp(theme: theme));
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
  const MyApp({super.key, required theme} );

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  ThemeData? theme;

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
      theme: theme,
      home: _user == null ? const SignIn() : const MyHomePage(),
      themeMode: ThemeMode.system,

    );
  }
}
