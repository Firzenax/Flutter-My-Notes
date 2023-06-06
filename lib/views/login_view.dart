import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:tuto/constants/routes.dart';

import '../utilities/show_error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
      appBar: AppBar(title: const Text("Login")),
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
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email, password: password);
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(notesRoute, (route) => false);
                }
              } on FirebaseAuthException catch (e) {
                if (e.message!.contains('user-not-found')) {
                  await showErrorDialog(context, "User not found");
                } else if (e.message!.contains('wrong-password')) {
                  await showErrorDialog(context, "Wrong password");
                } else {
                  await showErrorDialog(context, "error: ${e.message}");
                }
              } catch (e) {
                await showErrorDialog(context, e.toString());
              }
            },
            child: const Text("Login"),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(registerRoute, (route) => false);
              },
              child: const Text("Not registered ? register here"))
        ],
      ),
    );
  }
}
