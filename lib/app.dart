import 'package:flutter/material.dart';
import 'package:gelatin/features/themes/app_theme.dart';
import 'package:gelatin/features/themes/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/session/session_manager.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'No ThemeControllerScope found in context.');
    return scope!.notifier!;
  }
}

class GelatinApp extends StatelessWidget {
  GelatinApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  late final ThemeController themeController = ThemeController(prefs);

  Future<Widget> _start() async {
    final session = await SessionManager.load();

    if (session.isLoggedIn) {
      return HomePage(server: session.server!, token: session.token!);
    }

    return const ServerPage();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: themeController,
      child: AnimatedBuilder(
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
      ),
    );
  }
}
