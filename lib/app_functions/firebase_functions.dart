import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<bool> isStillLogedIn() async {
  if(FirebaseAuth.instance.currentUser != null) {
    return true;
  } else {
    return false;
  }
}

Future<void> signOutCurrentUser() async {
  await FirebaseAuth.instance.signOut();
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

Future<void> signUpUser(String name, String email, String password) async {
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    ).then((value) async {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      if (kDebugMode) {
        print('User created: ${value.user!.uid}');
      }
    });
  } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      if (kDebugMode) {
        print('The password provided is too weak.');
      }
    } else if (e.code == 'email-already-in-use') {
      if (kDebugMode) {
        print('The account already exists for that email.');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}


isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
  //   use token
    final idTokenResult = await user.getIdTokenResult();
    if (idTokenResult.claims?['admin'] == true) {
      return true;
    } else {
      return false;
    }

  }
  return FirebaseAuthException(code: 'user-not-signed-in', message: 'Currently no user is authenticated.');
}


