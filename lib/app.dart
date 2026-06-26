import 'package:flutter/material.dart';
import 'package:gelatin/features/themes/app_theme.dart';
import 'package:gelatin/features/themes/theme_controller.dart';

import 'core/session/session_manager.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

class GelatinApp extends StatelessWidget {
  const GelatinApp({super.key});

  static final ThemeController themeController = ThemeController();

  Future<Widget> _start() async {
    final session = await SessionManager.load();

    if (session.isLoggedIn) {
      return HomePage(server: session.server!, token: session.token!);
    }

    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
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
      },
    );
  }
}
