// import 'package:dds/dap.dart';
import 'package:devtools_app/src/primitives/message_bus.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'dart:convert';
import 'package:vm_service/vm_service.dart';
import '../primitives/message_bus.dart';
import '../primitives/utils.dart';
import '../service/vm_service_wrapper.dart';
import '../primitives/auto_dispose.dart';

import '../../devtools_app.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../screens/inspector/diagnostics_node.dart';
import '../screens/inspector/inspector_service.dart';
import '../screens/logging/logging_controller.dart';
import '../shared/globals.dart';
import 'idg_controller.dart';

// EventsAPI? _eventsAPI;

// EventsAPI get eventsAPI {
//   _eventsAPI ??= EventsAPI(globals.messageBus, globals.serviceManager);
//   return _eventsAPI!;
// }

class EventsAPI extends DisposableController with AutoDisposeControllerMixin {
  MessageBus _bus;
  ServiceConnectionManager serviceConnection;

  // Layering violation
  IDGController controller;

  EventsAPI(
    IDGController this.controller,
    MessageBus this._bus,
    ServiceConnectionManager this.serviceConnection,
  ) {
    autoDisposeStreamSubscription(
      serviceManager.onConnectionAvailable.listen(_handleConnectionStart),
    );
    if (serviceManager.connectedAppInitialized) {
      _handleConnectionStart(serviceManager.service!);
    }
    autoDisposeStreamSubscription(
      serviceManager.onConnectionClosed.listen(_handleConnectionStop),
    );
    _handleBusEvents();
  }

  void _handleConnectionStart(VmServiceWrapper service) async {
    print('_handleConnectionStart');

    // Log stdout events.
    final _StdoutEventHandler stdoutHandler =
        _StdoutEventHandler(controller, 'stdout');
    autoDisposeStreamSubscription(
      service.onStdoutEventWithHistory.listen(stdoutHandler.handle),
    );

    // Log GC events.
    autoDisposeStreamSubscription(service.onGCEvent.listen(_handleGCEvent));

    // Log `dart:developer` `log` events.
    autoDisposeStreamSubscription(
      service.onLoggingEventWithHistory.listen(_handleDeveloperLogEvent),
    );

    // Log Flutter extension events.
    autoDisposeStreamSubscription(
      service.onExtensionEventWithHistory.listen(_handleExtensionEvent),
    );
  }

  void _handleExtensionEvent(Event e) async {
    // Events to show without a summary in the table.
    const Set<String> untitledEvents = {
      'Flutter.FirstFrame',
      'Flutter.FrameworkInitialization',
    };

    // TODO(jacobr): make the list of filtered events configurable.
    const Set<String> filteredEvents = {
      // Suppress these events by default as they just add noise to the log
      ServiceExtensionStateChangedInfo.eventName,
    };

    if (filteredEvents.contains(e.extensionKind)) {
      return;
    }

    if (e.extensionKind == FrameInfo.eventName) {
      final FrameInfo frame = FrameInfo.from(e.extensionData!.data);

      final String frameId = '#${frame.number}';
      final String frameInfoText =
          '$frameId ${frame.elapsedMs!.toStringAsFixed(1).padLeft(4)}ms ';

      log(
        LogData(
          e.extensionKind!.toLowerCase(),
          jsonEncode(e.extensionData!.data),
          e.timestamp,
          summary: frameInfoText,
        ),
      );
    } else if (e.extensionKind == ImageSizesForFrame.eventName) {
      final images = ImageSizesForFrame.from(e.extensionData!.data);

      for (final image in images) {
        log(
          LogData(
            e.extensionKind!.toLowerCase(),
            jsonEncode(image.rawJson),
            e.timestamp,
            summary: image.summary,
          ),
        );
      }
    } else if (e.extensionKind == NavigationInfo.eventName) {
      final NavigationInfo navInfo = NavigationInfo.from(e.extensionData!.data);

      log(
        LogData(
          e.extensionKind!.toLowerCase(),
          jsonEncode(e.json),
          e.timestamp,
          summary: navInfo.routeDescription,
        ),
      );
    } else if (untitledEvents.contains(e.extensionKind)) {
      log(
        LogData(
          e.extensionKind!.toLowerCase(),
          jsonEncode(e.json),
          e.timestamp,
          summary: '',
        ),
      );
    } else if (e.extensionKind == ServiceExtensionStateChangedInfo.eventName) {
      final ServiceExtensionStateChangedInfo changedInfo =
          ServiceExtensionStateChangedInfo.from(e.extensionData!.data);

      log(
        LogData(
          e.extensionKind!.toLowerCase(),
          jsonEncode(e.json),
          e.timestamp,
          summary: '${changedInfo.extension}: ${changedInfo.value}',
        ),
      );
    } else if (e.extensionKind == 'Flutter.Error') {
      // TODO(pq): add tests for error extension handling once framework changes
      // are landed.
      final RemoteDiagnosticsNode node = RemoteDiagnosticsNode(
        e.extensionData!.data,
        objectGroup,
        false,
        null,
      );
      // Workaround the fact that the error objects from the server don't have
      // style error.
      node.style = DiagnosticsTreeStyle.error;
      // if (_verboseDebugging) {
      // logger.log('node toStringDeep:######\n${node.toStringDeep()}\n###');
      // }

      final RemoteDiagnosticsNode summary = _findFirstSummary(node) ?? node;
      log(
        LogData(
          e.extensionKind!.toLowerCase(),
          jsonEncode(e.extensionData!.data),
          e.timestamp,
          summary: summary.toDiagnosticsNode().toString(),
        ),
      );
    } else {
      log(
        LogData(
          e.extensionKind!.toLowerCase(),
          jsonEncode(e.json),
          e.timestamp,
          summary: e.json.toString(),
        ),
      );
    }
  }

  ObjectGroup get objectGroup =>
      serviceManager.consoleService.objectGroup as ObjectGroup;

  void _handleGCEvent(Event e) {
    final HeapSpace newSpace = HeapSpace.parse(e.json!['new'])!;
    final HeapSpace oldSpace = HeapSpace.parse(e.json!['old'])!;
    final isolateRef = e.json!['isolate'];

    final int usedBytes = newSpace.used! + oldSpace.used!;
    final int capacityBytes = newSpace.capacity! + oldSpace.capacity!;

    final int time = ((newSpace.time! + oldSpace.time!) * 1000).round();

    final String summary = '${isolateRef['name']} • '
        '${e.json!['reason']} collection in $time ms • '
        '${printMB(usedBytes, includeUnit: true)} used of ${printMB(capacityBytes, includeUnit: true)}';

    final event = <String, dynamic>{
      'reason': e.json!['reason'],
      'new': newSpace.json,
      'old': oldSpace.json,
      'isolate': isolateRef,
    };

    final String message = jsonEncode(event);
    log(LogData('gc', message, e.timestamp, summary: summary));
  }

  void _handleDeveloperLogEvent(Event e) {
    final VmServiceWrapper? service = serviceManager.service;

    final logRecord = e.json!['logRecord'];

    String? loggerName =
        _valueAsString(InstanceRef.parse(logRecord['loggerName']));
    if (loggerName == null || loggerName.isEmpty) {
      loggerName = 'log';
    }
    final int? level = logRecord['level'];
    final InstanceRef messageRef = InstanceRef.parse(logRecord['message'])!;
    String? summary = _valueAsString(messageRef);
    if (messageRef.valueAsStringIsTruncated == true) {
      summary = summary! + '...';
    }
    final InstanceRef? error = InstanceRef.parse(logRecord['error']);
    final InstanceRef? stackTrace = InstanceRef.parse(logRecord['stackTrace']);

    final String? details = summary;
    Future<String> Function()? detailsComputer;

    // If the message string was truncated by the VM, or the error object or
    // stackTrace objects were non-null, we need to ask the VM for more
    // information in order to render the log entry. We do this asynchronously
    // on-demand using the `detailsComputer` Future.
    if (messageRef.valueAsStringIsTruncated == true ||
        _isNotNull(error) ||
        _isNotNull(stackTrace)) {
      detailsComputer = () async {
        // Get the full string value of the message.
        String result =
            await _retrieveFullStringValue(service, e.isolate!, messageRef);

        // Get information about the error object. Some users of the
        // dart:developer log call may pass a data payload in the `error`
        // field, encoded as a json encoded string, so handle that case.
        if (_isNotNull(error)) {
          if (error!.valueAsString != null) {
            final String errorString =
                await _retrieveFullStringValue(service, e.isolate!, error);
            result += '\n\n$errorString';
          } else {
            // Call `toString()` on the error object and display that.
            final toStringResult = await service!.invoke(
              e.isolate!.id!,
              error.id!,
              'toString',
              <String>[],
              disableBreakpoints: true,
            );

            if (toStringResult is ErrorRef) {
              final String? errorString = _valueAsString(error);
              result += '\n\n$errorString';
            } else if (toStringResult is InstanceRef) {
              final String str = await _retrieveFullStringValue(
                service,
                e.isolate!,
                toStringResult,
              );
              result += '\n\n$str';
            }
          }
        }

        // Get info about the stackTrace object.
        if (_isNotNull(stackTrace)) {
          result += '\n\n${_valueAsString(stackTrace)}';
        }

        return result;
      };
    }

    const int severeIssue = 1000;
    final bool isError = level != null && level >= severeIssue ? true : false;

    log(
      LogData(
        loggerName,
        details,
        e.timestamp,
        isError: isError,
        summary: summary,
        detailsComputer: detailsComputer,
      ),
    );
  }

  bool _isNotNull(InstanceRef? serviceRef) {
    return serviceRef != null && serviceRef.kind != 'Null';
  }

  String? _valueAsString(InstanceRef? ref) {
    if (ref == null) {
      return null;
    }

    if (ref.valueAsString == null) {
      return ref.valueAsString;
    }

    if (ref.valueAsStringIsTruncated == true) {
      return '${ref.valueAsString}...';
    } else {
      return ref.valueAsString;
    }
  }

  void _handleConnectionStop(dynamic event) {}

  void _handleBusEvents() {
    // TODO(jacobr): expose the messageBus for use by vm tests.
    autoDisposeStreamSubscription(
      messageBus.onEvent(type: 'reload.end').listen((BusEvent event) {
        log(
          LogData(
            'hot.reload',
            event.data as String?,
            DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }),
    );

    autoDisposeStreamSubscription(
      messageBus.onEvent(type: 'restart.end').listen((BusEvent event) {
        log(
          LogData(
            'hot.restart',
            event.data as String?,
            DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }),
    );

    // Listen for debugger events.
    autoDisposeStreamSubscription(
      messageBus
          .onEvent()
          .where(
            (event) =>
                event.type == 'debugger' || event.type.startsWith('debugger.'),
          )
          .listen(_handleDebuggerEvent),
    );

    // Listen for DevTools internal events.
    autoDisposeStreamSubscription(
      messageBus
          .onEvent()
          .where((event) => event.type.startsWith('devtools.'))
          .listen(_handleDevToolsEvent),
    );
  }

  void _handleDebuggerEvent(BusEvent event) {
    final Event debuggerEvent = event.data as Event;

    // Filter ServiceExtensionAdded events as they're pretty noisy.
    if (debuggerEvent.kind == EventKind.kServiceExtensionAdded) {
      return;
    }

    log(
      LogData(
        event.type,
        jsonEncode(debuggerEvent.json),
        debuggerEvent.timestamp,
        summary: '${debuggerEvent.kind} ${debuggerEvent.isolate!.id}',
      ),
    );
  }

  static RemoteDiagnosticsNode? _findFirstSummary(RemoteDiagnosticsNode node) {
    if (node.level == DiagnosticLevel.summary) {
      return node;
    }
    RemoteDiagnosticsNode? summary;
    for (var property in node.inlineProperties) {
      summary = _findFirstSummary(property);
      if (summary != null) return summary;
    }

    for (RemoteDiagnosticsNode child in node.childrenNow) {
      summary = _findFirstSummary(child);
      if (summary != null) return summary;
    }

    return null;
  }

  void _handleDevToolsEvent(BusEvent event) {
    var details = event.data.toString();
    String? summary;

    if (details.contains('\n')) {
      final lines = details.split('\n');
      summary = lines.first;
      details = lines.sublist(1).join('\n');
    }

    log(
      LogData(
        event.type,
        details,
        DateTime.now().millisecondsSinceEpoch,
        summary: summary,
      ),
    );
  }

  void log(LogData log) => this.controller.log(log);
  //  .IDGController.log(IDGEvent(log.kind, log.details!));
  // void log(LogData log) => print(log);
// ;

}

/// Receive and log stdout / stderr events from the VM.
///
/// This class buffers the events for up to 1ms. This is in order to combine a
/// stdout message and its newline. Currently, `foo\n` is sent as two VM events;
/// we wait for up to 1ms when we get the `foo` event, to see if the next event
/// is a single newline. If so, we add the newline to the previous log message.
class _StdoutEventHandler {
  _StdoutEventHandler(
    this.controller,
    this.name, {
    this.isError = false,
  });

  final String name;
  final bool isError;
  IDGController controller;

  LogData? buffer;
  Timer? timer;

  void handle(Event e) {
    final String message = decodeBase64(e.bytes!);
    print('_StdOutEventHandler: $message');

    if (buffer != null) {
      timer?.cancel();

      if (message == '\n') {
        controller.log(
          LogData(
            buffer!.kind,
            buffer!.details! + message,
            buffer!.timestamp,
            summary: buffer!.summary! + message,
            isError: buffer!.isError,
          ),
        );
        buffer = null;
        return;
      }

      controller.log(buffer!);
      buffer = null;
    }

    const maxLength = 200;

    String summary = message;
    if (message.length > maxLength) {
      summary = message.substring(0, maxLength);
    }

    final LogData data = LogData(
      name,
      message,
      e.timestamp,
      summary: summary,
      isError: isError,
    );

    if (message == '\n') {
      controller.log(data);
    } else {
      buffer = data;
      timer = Timer(const Duration(milliseconds: 1), () {
        controller.log(buffer!);
        buffer = null;
      });
    }
  }
}

Future<String> _retrieveFullStringValue(
  VmServiceWrapper? service,
  IsolateRef isolateRef,
  InstanceRef stringRef,
) {
  final fallback = '${stringRef.valueAsString}...';
  // TODO(kenz): why is service null?

  return service
          ?.retrieveFullStringValue(
            isolateRef.id!,
            stringRef,
            onUnavailable: (truncatedValue) => fallback,
          )
          .then((value) => value != null ? value : fallback) ??
      Future.value(fallback);
}
