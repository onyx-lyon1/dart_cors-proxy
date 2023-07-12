import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/setCookies', _setCookiesHandler)
  ..get('/getCookies', _getCookiesHandler)
..post('/postEcho', _postEchoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message');
}

Response _setCookiesHandler(Request request) {
  final cookies = request.headers['cookie'];
  return Response.ok('$cookies');
}

Response _getCookiesHandler(Request request) {
  return Response.ok('ok', headers: {'set-cookie': 'foo=bar'});
}

Future<Response> _postEchoHandler(Request request) async {
  return Response.ok(await (request.readAsString()));
}

void main() async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
