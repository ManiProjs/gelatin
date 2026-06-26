import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ServerDiscovery {
  static const _ssdpAddress = '239.255.255.250';
  static const _ssdpPort = 1900;

  Future<List<String>> discover({void Function(String server)? onFound}) async {
    final results = <String>{};

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
      reusePort: true,
    );
    socket.broadcastEnabled = true;
    socket.multicastLoopback = true;
    socket.joinMulticast(InternetAddress(_ssdpAddress));

    final request = [
      'M-SEARCH * HTTP/1.1',
      'HOST: $_ssdpAddress:$_ssdpPort',
      'MAN: "ssdp:discover"',
      'MX: 3',
      'ST: ssdp:all',
      '',
      '',
    ].join('\r\n');

    socket.send(utf8.encode(request), InternetAddress(_ssdpAddress), _ssdpPort);

    final completer = Completer<List<String>>();
    Timer? idleTimer;

    void finish() {
      if (!completer.isCompleted) {
        completer.complete(results.toList());
      }
      socket.close();
    }

    void resetIdle() {
      idleTimer?.cancel();
      idleTimer = Timer(const Duration(seconds: 2), finish);
    }

    Timer(const Duration(seconds: 6), finish);

    socket.listen(
      (event) {
        if (event != RawSocketEvent.read) return;

        final dg = socket.receive();
        if (dg == null) return;

        final data = utf8.decode(dg.data, allowMalformed: true);

        final location = _extractLocation(data);

        if (location != null) {
          final cleaned = location.trim();

          if (cleaned.contains(':8096')) {
            if (results.add(cleaned)) {
              onFound?.call(cleaned);
            }
            resetIdle();
          }
        }
      },
      onError: (e) {
        // ignore network errors for discovery
      },
      cancelOnError: false,
    );

    final ssdpResults = await completer.future;

    // If SSDP found servers, return immediately
    if (ssdpResults.isNotEmpty) {
      return ssdpResults;
    }

    // Fallback: port scan if SSDP fails
    final fallbackResults = await _scanSubnetForJellyfin();

    return fallbackResults;
  }

  String? _extractLocation(String response) {
    final lines = response.split(RegExp(r'\r?\n'));

    for (final line in lines) {
      final idx = line.toLowerCase().indexOf('location:');
      if (idx != -1) {
        return line.substring(idx + 9).trim();
      }
    }

    return null;
  }
}

Future<List<String>> _scanSubnetForJellyfin() async {
  final results = <String>{};

  try {
    final interfaces = await NetworkInterface.list();

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length != 4) continue;

        final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

        // small fast scan (avoid full 254 range)
        for (int i = 1; i <= 50; i++) {
          final host = '$subnet.$i';

          try {
            final socket = await Socket.connect(
              host,
              8096,
              timeout: const Duration(milliseconds: 120),
            );
            socket.destroy();
            results.add('http://$host:8096');
          } catch (_) {}
        }
      }
    }
  } catch (_) {}

  return results.toList();
}
