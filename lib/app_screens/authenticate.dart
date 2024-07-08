import 'package:flutter/material.dart';
import 'package:ncba_news/app_sections/signin.dart';
import 'package:ncba_news/app_sections/signup.dart';

import '../app_sections/forgot_password.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            'NCBA News',
            style: TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Sign In'),
              Tab(text: 'Sign Up'),
            ],
          ),
        ),
        body:  TabBarView(
          children: <Widget>[
            SignIn(),
            const Signup(),
          ],
        ),
      ),
    );
  }
}
