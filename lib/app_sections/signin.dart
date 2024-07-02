import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ncba_news/app_sections/forgot_password.dart';

class SignIn extends StatefulWidget {
  SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        print("Sign-in successful"); // Replace with your desired action
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("No user found for that email."),
          ));
        } else if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Wrong password provided for that user."),
          ));
        } else {
          // Generic error handling
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${e.message}"),
          ));
        }
      }
    }
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => ForgotPassword(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Form(
          key: _formKey,
          child: SizedBox(
            width: 320,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0.0,
                        horizontal: 20.0,
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
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0.0,
                        horizontal: 20.0,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _signIn,
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 20.0),
                TextButton(
                  onPressed: _showForgotPasswordSheet,
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
