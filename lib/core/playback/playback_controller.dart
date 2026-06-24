import 'playback_service.dart';

class PlaybackController {
  final PlaybackService service;

  PlaybackController(this.service);

  Future<String> resolve(String itemId) async {
    final info = await service.getStreamInfo(itemId);

    return service.buildHlsUrl(info);
  }
}
