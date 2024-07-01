import 'package:flutter/material.dart';
import 'package:ncba_news/app_sections/forgot_password.dart';
import 'package:ncba_news/app_sections/signin.dart';
import 'package:ncba_news/app_sections/signup.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate>  {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            children: [
              SizedBox(height: 20.0),
              Text('NCBA News', style: TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold)),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(100.0),
            child: TabBar(
              tabs: <Widget>[
                Tab(text: 'Sign In'),
                Tab(text: 'Sign Up'),
                Tab(text: 'Forgot Password?')
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            Center(
              child: SignIn(),
            ),
            Center(
              child: Signup(),
            ),
            Center(
              child: ForgotPassword(),
            ),
          ],
        ),
      ),
    );
  }
}
