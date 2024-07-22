import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ncba_news/app.dart';import 'package:ncba_news/app_sections/forgot_password.dart';
import 'package:ncba_news/app_screens/signup.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late bool _passwordHidden = true;


  void _signInPressed() {
    if (_formKey.currentState!.validate()) {
      signInUser(_emailController.text, _passwordController.text).then((value) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value[1]),
        ));
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()), // Replace with your SignIn page
              (route) => false,);
      });
    }
  }

  Future<List<dynamic>> signInUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return [true, 'Sign In Successful.'];
    } on FirebaseAuthException catch (e) {
      return [false, e.message];
    } catch (e) {
      return [false, 'An error occurred. Please try again.'];
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
                          TextButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPassword()),
                            );
                          }, child: const Text('Forgot Password?')),
                        ],
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _passwordHidden,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          suffixIcon: IconButton(onPressed: (){
                            setState(() {
                              _passwordHidden = !_passwordHidden;
                            });
                          }, icon: Icon(_passwordHidden ? Icons.visibility_off : Icons.visibility))
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
                        onPressed: ()  {
                          _signInPressed();
                        },
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
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Signup()),
                          );
                        },
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
