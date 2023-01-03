import 'package:flutter/foundation.dart';

import '../../extensibility/discoverable.dart';
import '../../shared/analytics/constants.dart' as analytics_constants;
import '../../shared/globals.dart';
import '../../shared/primitives/simple_items.dart';
import 'memory_controller.dart';
import 'memory_screen.dart';

class DiscoverableMemoryPage extends DiscoverablePage {
  DiscoverableMemoryPage(this.controller) : super() {
    discoverableApp.pages[id] = this;
  }

  final MemoryController controller;

  static String get id => MemoryScreen.id;

  void takeSnapshotAction() {
    final takeSnapshot = controller.diffPaneController.takeSnapshotHandler(
      analytics_constants.MemoryEvent.diffTakeSnapshotControlPane,
    );
    if (takeSnapshot == null)
      print("takeSnapshotHandler returned null, can't take snapshot");
    else
      takeSnapshot();
  }

  void changeTabAction(Key tab) {
    controller.currentTab.value = tab;
  }

  @override
  void selectElement(String key) {
    eventsManager.addEvent(
      StructuredLogEvent(EventIds.selectElementEvent, data: {'key': key}),
    );
    if (key == WidgetIds.takeSnapshotButton) {
      takeSnapshotAction();
      return;
    }
    controller.currentTab.value = Key(key);
  }

  @override
  void highlightElement(String key) {
    eventsManager.addEvent(
      StructuredLogEvent(EventIds.highlightElementEvent, data: {'key': key}),
    );
    if (discoverableApp.highlightableElements.keys.contains(Key(key))) {
      discoverableApp.highlightableElements[Key(key)]
          ?.toggleIsHighlighted(true);
      return;
    }
  }
}
