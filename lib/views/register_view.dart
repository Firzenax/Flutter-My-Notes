import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "dart:developer" as devtools show log;

import 'package:tuto/constants/routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: Column(
        children: [
          TextField(
            enableSuggestions: false,
            autocorrect: false,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration:
                const InputDecoration(hintText: "Enter your email here"),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration:
                const InputDecoration(hintText: "Enter your password here"),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;

              try {
                final userCredentials = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                        email: email, password: password);
                devtools.log(userCredentials.toString());
              } on FirebaseAuthException catch (e) {
                if (e.message!.contains("email-already-in-use")) {
                  devtools.log("Email is already used");
                } else if (e.message!.contains("weak-password")) {
                  devtools.log("Password too weak");
                } else if (e.message!.contains("invalid-email")) {
                  devtools.log("Invalid email");
                } else {
                  devtools.log(e.toString());
                }
              }
            },
            child: const Text("Register"),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text("Already have an account ? log in here"))
        ],
      ),
    );
  }
}
