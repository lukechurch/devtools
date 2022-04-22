import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'idg_controller.dart';
import 'dart:async';

late IDGServer server;

// void start() {
// if (server != null) server = IDGServer();
// server.start();
// }

class IDGServer {
  final IDGController controller;
  IDGServer(this.controller) {
    print('IDGServer.ctor');
  }

  start() async {
    // Open a port on the machine to listen on
    print('IDGServer.start');
    var handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

    var server = await shelf_io.serve(handler, '127.0.0.1', 9999);

    // Enable content compression
    server.autoCompress = true;

    print('Serving at http://${server.address.host}:${server.port}');
  }

  Response _echoRequest(Request request) {
    String reqUrl = Uri.decodeFull(request.url.toString());
    controller.log(LogData(
      'vscode',
      reqUrl,
      DateTime.now().millisecondsSinceEpoch,
      summary: reqUrl,
      isError: false,
    ));
    // }

    return Response.ok('Request for "${request.url}"');
  }
}
