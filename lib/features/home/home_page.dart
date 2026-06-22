import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String server;
  final String token;

  const HomePage({super.key, required this.server, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gelatin')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Logged in 🎬'),
            const SizedBox(height: 12),
            Text('Server: $server'),
          ],
        ),
      ),
    );
  }
}
