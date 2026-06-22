import 'package:flutter/material.dart';

import 'core/session/session_manager.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

class GelatinApp extends StatelessWidget {
  const GelatinApp({super.key});

  Future<Widget> _start() async {
    final session = await SessionManager.load();

    if (session.isLoggedIn) {
      return HomePage(server: session.server!, token: session.token!);
    }

    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _start(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
