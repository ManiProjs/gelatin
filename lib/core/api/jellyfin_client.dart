import 'package:dio/dio.dart';

import '../models/auth_result.dart';

class JellyfinClient {
  final Dio dio;
  final String serverUrl;
  final String? token;

  JellyfinClient(this.serverUrl, {this.token})
    : dio = Dio(BaseOptions(baseUrl: serverUrl));

  Options get _authOptions => Options(
    headers: {
      if (token != null) 'X-Emby-Token': token,
      'Content-Type': 'application/json',
    },
  );

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post(
      '/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
      options: Options(
        headers: {
          'X-Emby-Authorization':
              'MediaBrowser Client="Gelatin", Device="Desktop", DeviceId="gelatin", Version="0.1.0"',
        },
      ),
    );

    return AuthResult.fromJson(response.data);
  }

  Future<Response> getLibraries() {
    return dio.get('/Library/MediaFolders', options: _authOptions);
  }
}
