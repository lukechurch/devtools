import 'package:flutter/foundation.dart';

import '../../discoverable_facade/discoverable_devtools.dart';
import '../../shared/analytics/constants.dart' as analytics_constants;
import '../../shared/globals.dart';
import '../../shared/primitives/simple_items.dart';
import 'memory_controller.dart';
import 'memory_screen.dart';

class MemoryDiscoverableFacade extends DiscoverablePage {
  MemoryDiscoverableFacade(this.controller) : super() {
    discoverableApp.pages[id] = this;
  }

  final MemoryController controller;

  static String get id => MemoryScreen.id;

  void takeSnapshotAction() {
    final takeSnapshot = controller.controllers.diff.takeSnapshotHandler(
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
      StructuredLogEvent(EventKeys.selectElementEvent.id, data: {'key': key}),
    );
    if (key == WidgetKeys.takeSnapshotButton.id) {
      takeSnapshotAction();
      return;
    }
    controller.currentTab.value = Key(key);
  }

  @override
  void highlightElement(String key) {
    eventsManager.addEvent(
      StructuredLogEvent(
        EventKeys.highlightElementEvent.id,
        data: {'key': key},
      ),
    );
    if (discoverableApp.highlightableElements.keys.contains(Key(key))) {
      discoverableApp.highlightableElements[Key(key)]
          ?.toggleIsHighlighted(true);
      return;
    }
  }
}
