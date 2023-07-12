import 'dart:convert';
import 'dart:io';
import 'package:requests/requests.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:http/http.dart' as http;

Future<void> main() async {
  final handler = const Pipeline().addHandler(proxyHandler);

  int port = int.parse(Platform.environment['PORT'] ?? '3000');
  await shelf_io.serve(
    handler,
    '0.0.0.0',
    port,
  );
  print('Le proxy CORS est en cours d\'exécution sur le port $port .');
}

Map<String, String> corsFullAuthorize(Request request){
  return {
    HttpHeaders.accessControlAllowOriginHeader: request.headers['origin'] ?? "*",
    HttpHeaders.accessControlAllowMethodsHeader: 'GET, POST, PUT, DELETE, OPTIONS',
    HttpHeaders.accessControlAllowHeadersHeader: request.headers['Access-Control-Request-Headers'] ?? "",
    HttpHeaders.accessControlAllowCredentialsHeader: 'true',
    HttpHeaders.accessControlMaxAgeHeader: '1728000',
    HttpHeaders.accessControlExposeHeadersHeader: "location-proxied, set-cookie-proxied"
  };
}

// Gère la redirection de la requête et la réponse
Future<Response> proxyHandler(Request request) async {
  if (request.method.toUpperCase() == 'OPTIONS') {
    return Response.ok(null, headers: corsFullAuthorize(request));
  }

  final url = Uri.decodeFull(request.url.toString());
  http.Client client = http.Client();
  Map<String, String>? requestHeaders = Map.from(request.headers);
  bool followRedirects = true;
  if (requestHeaders.containsKey("follow-redirects")) {
    followRedirects = requestHeaders['follow-redirects'] == 'true';
    requestHeaders.remove('follow-redirects');
  }
  requestHeaders['host'] = Uri.parse(url).host;

  // requestHeaders = requestHeaders.map((key, value) => MapEntry(key.replaceAll("-proxied", ""), value));

  if (requestHeaders.containsKey("cookie-proxied")) {
    requestHeaders['cookie'] = requestHeaders['cookie-proxied']!;
    requestHeaders.remove('cookie-proxied');
  }
  http.Request req = http.Request(
    request.method,
    Uri.parse(url),
  );
  req.headers.addAll(requestHeaders);
  req.followRedirects = followRedirects;
  if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(request.method)) {
    req.body = await request.readAsString();
  }
  http.Response resp = await http.Response.fromStream(await client.send(req));

  Map<String, String> headers = Map.from(resp.headers);
  if (headers.containsKey("set-cookie")) {
    headers['set-cookie-proxied'] = headers['set-cookie']!;
    headers.remove('set-cookie');
  }

  if (headers.containsKey("location")) {
    if (!followRedirects) {
      headers['location-proxied'] = headers['location']!;
      headers.remove('location');
    } else {
      if (headers['location']!.startsWith("/")) {
        headers['location'] =
            "https://${request.headers['host']!}/$url${headers['location']!}";
      } else {
        headers['location'] =
            "https://${request.headers['host']!}/${headers['location']!}";
      }
    }
  }

  // remove content-length, content-encoding, transfer-encoding because when we respond we re-encode the body
  headers.remove(HttpHeaders.contentLengthHeader);
  headers.remove(HttpHeaders.contentEncodingHeader);
  headers.remove(HttpHeaders.transferEncodingHeader);
  headers.addAll(corsFullAuthorize(request));
  Response response = Response(
    resp.statusCode,
    body: resp.body,
    headers: headers,
    encoding: Encoding.getByName(resp.contentType),
  );
  return response;
}
