
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../shared/globals.dart';
import '../shared/primitives/highlightable.dart';
import '../shared/primitives/simple_items.dart';

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
    setGlobal(DiscoverableDevToolsApp, this);
    frameworkController.onPageChange.listen((event) {
      _selectedPageId = event.id;
    });
  }

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
      if (action == ActionKeys.selectElementAction.id) {
        page.selectElement(elementId);
      } else if (action == ActionKeys.highlightElementAction.id) {
        page.highlightElement(elementId);
      }
    }
  }

  final highlightableElements = <Key, HighlightableMixin>{};
}

abstract class DiscoverablePage {
  void selectElement(String key);
  void highlightElement(String key);
}
