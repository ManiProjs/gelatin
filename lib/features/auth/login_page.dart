import 'package:flutter/material.dart';
import 'package:gelatin/core/storage/auth_storage.dart';
import 'package:gelatin/features/home/home_page.dart';
import '../../core/api/jellyfin_client.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final serverController = TextEditingController();

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

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final server = serverController.text.trim();
    if (server.isEmpty) return;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(server: server)),
    );
  }
}

class LoginPage extends StatefulWidget {
  final String server;
  const LoginPage({super.key, required this.server});

  @override
  State<LoginPage> createState() => _LoginPageStateAuth();
}

class _LoginPageStateAuth extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ServerPage()),
              (route) => false,
            );
          },
        ),
      ),
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
      final client = JellyfinClient(widget.server);

      final auth = await client.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      await AuthStorage.saveAuth(
        token: auth.accessToken,
        server: widget.server,
        userId: auth.userId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomePage(server: widget.server, token: auth.accessToken),
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
