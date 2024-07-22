import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:ncba_news/app.dart';
import 'package:ncba_news/app_screens/signin.dart';
import 'package:ncba_news/app_screens/verification.dart';
import 'package:ncba_news/app_screens/no_connection.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ThemeData? theme;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final themeStr = await rootBundle.loadString('assets/theme.json');
    final themeJSON = jsonDecode(themeStr);
    theme = ThemeDecoder.decodeThemeData(themeJSON);
  } catch (e) {
    print('Error initializing Firebase or loading theme: $e');
    // Use default theme or handle error as needed
    theme = ThemeData.light(); // Fallback theme
  }

  runApp(MyApp(theme: theme));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.theme});

  final ThemeData? theme;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  bool _connected = true;
  bool _checkingConnection = true;

  late StreamSubscription<InternetStatus> connectionListener;
  Timer? _connectionTimer;
  late StreamSubscription<User?> authStateSubscription;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });

    connectionListener = InternetConnection().onStatusChange.listen((InternetStatus status) {
      setState(() {
        _connected = (status == InternetStatus.connected);
        if (_connected) {
          _checkingConnection = false;
        }
      });
    });

    _connectionTimer = Timer(const Duration(seconds: 30), () {
      setState(() {
        _checkingConnection = false;
      });
    });
  }


  @override
  void dispose() {
    connectionListener.cancel();
    _connectionTimer?.cancel();
    authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingConnection) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Widget homeWidget;

    if (!_connected) {
      homeWidget = const NoConnection();
    } else if (_user == null) {
      homeWidget = const SignIn();
    } else if (!_user!.emailVerified) {
      homeWidget = const Verification();
    } else {
      homeWidget = const MyHomePage(); // Make sure to create this screen
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NCBA News',
      theme: widget.theme,
      home: homeWidget,
      themeMode: ThemeMode.light,
      routes: {
        '/signin': (context) => const SignIn(),
        '/home': (context) => const MyHomePage(),
        // Add other routes here
      },
    );
  }
}
