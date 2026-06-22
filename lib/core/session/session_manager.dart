import '../storage/auth_storage.dart';

class SessionManager {
  final String? token;
  final String? server;
  final String? userId;

  const SessionManager({this.token, this.server, this.userId});

  static Future<SessionManager> load() async {
    final token = await AuthStorage.token;
    final server = await AuthStorage.server;
    final userId = await AuthStorage.userId;

    return SessionManager(token: token, server: server, userId: userId);
  }

  bool get isLoggedIn => token != null && server != null && userId != null;
}
