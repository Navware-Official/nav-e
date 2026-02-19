import 'dart:io';

import 'package:path/path.dart' as path;

/// Serves vector tiles from a directory layout {z}/{x}/{y}.pbf over HTTP on localhost.
/// No SQLite: tiles are plain files; app database stays in Rust.
class LocalTileServer {
  LocalTileServer._({
    required this.port,
    required this.baseUrl,
    required HttpServer server,
    required String tilesDir,
  }) : _server = server,
       _tilesDir = tilesDir;

  final int port;
  final String baseUrl;
  final HttpServer _server;
  final String _tilesDir;

  static const String _tilesPathPrefix = '/tiles/';

  /// Start serving tiles from [tilesDirectoryPath] (region root: z/x/y.pbf under it).
  /// Returns server with [baseUrl] (e.g. http://127.0.0.1:port).
  static Future<LocalTileServer> start(String tilesDirectoryPath) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final baseUrl = 'http://127.0.0.1:$port';

    final tileServer = LocalTileServer._(
      port: port,
      baseUrl: baseUrl,
      server: server,
      tilesDir: tilesDirectoryPath,
    );

    server.listen((request) => tileServer._handleRequest(request));

    return tileServer;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }

    final uriPath = request.uri.path;
    if (!uriPath.startsWith(_tilesPathPrefix)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final segments = uriPath
        .substring(_tilesPathPrefix.length)
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.length != 3) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final z = int.tryParse(segments[0]);
    final x = int.tryParse(segments[1]);
    final y = int.tryParse(segments[2]);
    if (z == null || x == null || y == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final tileFile = File(path.join(_tilesDir, '$z', '$x', '$y.pbf'));
    if (!await tileFile.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final bytes = await tileFile.readAsBytes();
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.set('Content-Type', 'application/x-protobuf');
      request.response.add(bytes);
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  /// Stop the server.
  Future<void> stop() async {
    await _server.close(force: true);
  }
}
