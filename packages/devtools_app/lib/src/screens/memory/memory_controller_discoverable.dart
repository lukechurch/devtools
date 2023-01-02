import 'package:flutter/foundation.dart';

import '../../../devtools_app.dart';
import '../../analytics/constants.dart' as analytics_constants;
import '../../extensibility/discoverable.dart';
import '../../primitives/simple_items.dart';
import 'memory_tabs.dart';
import 'panes/diff/widgets/snapshot_list.dart';

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
      discoverableApp
          .highlightableElements[const Key(WidgetIds.takeSnapshotButton)]
          ?.toggleIsHighlighted(true);
      return;
    }
    controller.highlightTab.value = Key(key);
  }
}
