import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  final port = '8080';
  final host = 'http://0.0.0.0:$port';
  final testingPort = '8081';
  final testingHost = 'http://0.0.0.0:$testingPort';
  late Process p;
  late Process testingP;

  setUpAll(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port},
    );
    testingP = await Process.start(
      'dart',
      ['run', 'test/testing_server.dart'],
      environment: {'PORT': testingPort},
    );
    // Wait for server to start and print to stdout.
    await p.stdout.first;
    await testingP.stdout.first;
  });

  tearDownAll(() {
    p.kill();
    testingP.kill();
  });

  test('Root', () async {
    Uri uri = Uri.parse('$host/$testingHost/');
    final response = await get(uri);
    expect(response.statusCode, 200);
    expect(response.body, 'Hello, World!');
  });

  test('Echo', () async {
    final response = await get(Uri.parse('$host/$testingHost/echo/hello'));
    expect(response.statusCode, 200);
    expect(response.body, 'hello');
  });

  test('404', () async {
    final response = await get(Uri.parse('$host/$testingHost/foobar'));
    expect(response.statusCode, 404);
  });

  //I think this is not needed but I'm not shure of my cors knowledge
  // test('cors', () async {
  //   final response = await get(Uri.parse('$host/$testingHost/echo/hello'));
  //   expect(response.statusCode, 200);
  //   expect(response.body, 'hello');
  //   expect(response.headers['access-control-allow-origin'], '*');
  //   expect(response.headers['access-control-allow-methods'], 'GET, POST, OPTIONS');
  //   expect(response.headers['access-control-allow-headers'], '*');
  // });

  test('Set cookies', () async {
    final response = await get(Uri.parse('$host/$testingHost/setCookies'),
        headers: {'cookie-unsecure': 'foo=bar'});
    expect(response.statusCode, 200);
    expect(response.body, 'foo=bar');
  });

  test('Get cookies', () async {
    final response = await get(Uri.parse('$host/$testingHost/getCookies'));
    expect(response.statusCode, 200);
    expect(response.headers['set-cookie-unsecure'], 'foo=bar');
  });

  test('Post echo', () async {
    final response = await post(Uri.parse('$host/$testingHost/postEcho'), body: 'hello');
    expect(response.statusCode, 200);
    expect(response.body, 'hello');
  });
}
