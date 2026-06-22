import 'package:dio/dio.dart';

class JellyfinApi {
  final String server;
  final String token;

  late final Dio dio;

  JellyfinApi({required this.server, required this.token}) {
    dio = Dio(
      BaseOptions(
        baseUrl: server,
        headers: {'X-Emby-Token': token, 'Content-Type': 'application/json'},
      ),
    );
  }

  Future<List<dynamic>> getLibraries() async {
    final res = await dio.get('/Library/MediaFolders');
    return res.data['Items'] ?? [];
  }

  Future<List<dynamic>> getItems(String parentId) async {
    final res = await dio.get(
      '/Items',
      queryParameters: {
        'ParentId': parentId,
        'Recursive': true,
        'Fields': 'PrimaryImageAspectRatio,MediaSourceCount,Overview',
      },
    );

    return res.data['Items'] ?? [];
  }
}
