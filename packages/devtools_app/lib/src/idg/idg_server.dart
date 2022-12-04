import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../devtools_app.dart';
import 'idg_controller.dart';

late IDGServer server;

// void start() {
// if (server != null) server = IDGServer();
// server.start();
// }

class IDGServer {
  IDGServer(this.controller) {
    print('IDGServer.ctor');
  }
  final IDGController controller;

  void start() async {
    // Open a port on the machine to listen on
    print('IDGServer.start');
    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

    final server = await shelf_io.serve(handler, '127.0.0.1', 9999);

    // Enable content compression
    server.autoCompress = true;

    print('Serving at http://${server.address.host}:${server.port}');
  }

  Response _echoRequest(Request request) {
    final String reqUrl = Uri.decodeFull(request.url.toString());
    eventsManager.addEvent(
      StructuredLogEvent('vscode', data: {
        'data': reqUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'summary': reqUrl,
      }),
    );

    return Response.ok('Request for "${request.url}"');
  }
}
