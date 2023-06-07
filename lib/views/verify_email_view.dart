import 'package:flutter/material.dart';
import 'package:tuto/constants/routes.dart';
import 'package:tuto/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify email")),
      body: Column(children: [
        const Text("We've already sent an email verification"),
        const Text("Please verify your mailbox"),
        TextButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text("Send email verification")),
        TextButton(
            onPressed: () async {
              await AuthService.firebase().logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              }
            },
            child: const Text("Go back to login screen"))
      ]),
    );
  }
}
