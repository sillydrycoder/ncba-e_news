import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';import 'package:ncba_news/app_sections/forgot_password.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _signInPressed() {
    if (_formKey.currentState!.validate()) {
      signInUser(_emailController.text, _passwordController.text).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value),
        ));
      });
    }
  }

  signInUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).then((value) {
        return 'Sign In Successful.';
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'User not found.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password.';
      }
    }
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => const ForgotPassword(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/images/ncba_logo.png',
                      height: 40,
                    ),
                  ),
                  const Text(
                    'NCBA&E News',
                    style: TextStyle(
                      fontSize: 35.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              Container(
                width: 320,
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20.0),
                      TextFormField(
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Expanded(child: Container()),
                          TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                        ],
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          suffixIcon: Icon(Icons.visibility_off),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: _signInPressed,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(height: 20.0),
                      TextButton(
                        onPressed: _showForgotPasswordSheet,
                        child: const Text("Don't have an account?"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
