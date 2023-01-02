import 'dart:async';

import 'package:flutter/widgets.dart';

import '../primitives/highlightable_mixin.dart';
import '../primitives/simple_items.dart';
import '../shared/globals.dart';
import 'services_proxy.dart';

export '../screens/memory/memory_controller_discoverable.dart';
export '../screens/performance/performance_controller_discoverable.dart';

class StructuredLogEvent {
  StructuredLogEvent(this.type, {this.data});
  final String type;
  final Object? data;

  @override
  String toString() {
    return '$runtimeType: {type: $type, data: $data}';
  }
}

class VMEvent extends StructuredLogEvent {
  VMEvent(type, {data}) : super(type, data: data);
}

class DevToolsUserEvent extends StructuredLogEvent {
  DevToolsUserEvent(type, {data}) : super(type, data: data);
}

/// An event manager class. Clients can listen for classes of events, optionally
/// filtered by a string type. This can be used to decouple events sources and
/// event listeners.
class EventsManager {
  EventsManager() {
    _controller = StreamController.broadcast();
    setGlobal(EventsManager, this);
  }

  late StreamController<StructuredLogEvent> _controller;

  /// Listen for events. Clients can pass in an optional [type]
  /// which filters the events to only those specific ones.
  /// To stop listening to events, keep a reference to the resulting
  /// [StreamSubscription] and cancel it.
  Stream<StructuredLogEvent> onEvent({String? type}) {
    if (type == null) {
      return _controller.stream;
    } else {
      return _controller.stream.where(
        (StructuredLogEvent event) =>
            event.type == type || event.type.startsWith(type),
      );
    }
  }

  /// Add an event to the event bus.
  void addEvent(StructuredLogEvent event) {
    _controller.add(event);
  }

  /// Close (destroy) this [StructuredLogEventsManager]. This is generally not used
  /// outside of a testing context. All stream listeners will be closed and the
  /// bus will not fire any more events.
  void close() {
    unawaited(_controller.close());
  }
}

class DiscoverableDevToolsApp {
  DiscoverableDevToolsApp() {
    vmServicesProxy = VMServicesProxy();
    setGlobal(DiscoverableDevToolsApp, this);
    frameworkController.onPageChange.listen((event) {
      _selectedPageId = event.id;
    });
  }

  late VMServicesProxy vmServicesProxy;

  /// Get the available screen ids from [ScreenIds] class.
  Future<DiscoverablePage?> selectPage(String pageId) async {
    frameworkController.notifyShowPageId(pageId);
    if (pageId == selectedPageId) return pages[pageId];
    final value = await frameworkController.onPageChange.first;
    return pages[value.id];
  }

  String? _selectedPageId;
  String? get selectedPageId => _selectedPageId;

  Map<String, DiscoverablePage> pages = {};

  /// [actionUrl] is expected to be of the format:
  /// devtools://page-id/element-id?actions=action-list
  Future<void> handleActionPath(String actionUrl) async {
    final uri = Uri.parse(actionUrl);
    if (uri.host.isEmpty) return;
    final page = await discoverableApp.selectPage(uri.host);
    if (page == null) return;

    if (uri.pathSegments.isEmpty) return;
    final elementId = uri.pathSegments.first;
    final actions =
        (uri.queryParameters[internalUriActionQueryKey] ?? '').split(',');
    for (final action in actions) {
      switch (action) {
        case ActionIds.selectElementAction:
          page.selectElement(elementId);
          break;
        case ActionIds.highlightElementAction:
          page.highlightElement(elementId);
          break;
        default:
      }
    }
  }

  final highlightableElements = <Key, HighlightableMixin>{};
}

abstract class DiscoverablePage {
  void selectElement(String key);
  void highlightElement(String key);
}
