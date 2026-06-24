import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/jellyfin_api.dart';

class PlaybackService {
  final JellyfinApi api;

  PlaybackService(this.api);

  Future<StreamInfo> getStreamInfo(String itemId) async {
    final url = Uri.parse('${api.server}/Items/$itemId/PlaybackInfo');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'X-Emby-Token': api.token},
      body: jsonEncode({
        "EnableDirectPlay": true,
        "EnableDirectStream": true,
        "EnableTranscoding": true,
        "MaxStreamingBitrate": 30000000,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('PlaybackInfo failed: ${res.body}');
    }

    final data = jsonDecode(res.body);
    final source = (data['MediaSources'] as List).first;

    return StreamInfo(
      itemId: itemId,
      mediaSourceId: source['Id'],
      container: source['Container'] ?? 'mp4',
    );
  }

  String buildHlsUrl(StreamInfo info) {
    return '${api.server}/Videos/${info.itemId}/main.m3u8'
        '?mediaSourceId=${info.mediaSourceId}'
        '&api_key=${api.token}';
  }

  String buildDirectUrl(StreamInfo info) {
    return '${api.server}/Videos/${info.mediaSourceId}/stream.${info.container}?api_key=${api.token}';
  }
}

class StreamInfo {
  final String itemId;
  final String mediaSourceId;
  final String container;

  StreamInfo({
    required this.itemId,
    required this.mediaSourceId,
    required this.container,
  });
}
