import 'playback_service.dart';

class PlaybackController {
  final PlaybackService service;

  PlaybackController(this.service);

  Future<String> resolve(String itemId) async {
    try {
      final info = await service
          .getStreamInfo(itemId)
          .timeout(const Duration(seconds: 10));

      final url = service.buildHlsUrl(info);

      return url;
    } catch (e) {
      // Prevent app crash on playback failure
      return '';
    }
  }
}
