# 🌐 dart_cors_proxy

A server app built using [Shelf](https://pub.dev/packages/shelf),
configured to enable running with [Docker](https://www.docker.com/).

This sample code handles HTTP GET requests to `/` and `/echo/<message>`

## 🚀 Running the sample

### Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/server.dart
Server listening on port 3000
```

And then from a second terminal:
```
$ curl http://0.0.0.0:3000/https://google.com
(the google page)
```

### ⚡️ Running with Docker

If you have [Docker Desktop](https://www.docker.com/get-started) installed, you
can build and run with the `docker` command:

```
$ docker build . -t dart_cors_proxy
$ docker run -it -p 3000:3000 myserver
Server listening on port 3000
```

And then from a second terminal:
```
$ curl http://0.0.0.0:3000/https://google.com
(the google page)
```