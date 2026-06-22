import 'package:flutter/material.dart';
import 'package:gelatin/core/storage/auth_storage.dart';
import 'package:gelatin/features/home/home_page.dart';
import '../../core/api/jellyfin_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final serverController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gelatin',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: serverController,
                    decoration: const InputDecoration(labelText: 'Server URL'),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _connect,
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    try {
      final client = JellyfinClient(serverController.text.trim());

      final auth = await client.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      await AuthStorage.saveAuth(
        token: auth.accessToken,
        server: serverController.text.trim(),
        userId: auth.userId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            server: serverController.text.trim(),
            token: auth.accessToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
