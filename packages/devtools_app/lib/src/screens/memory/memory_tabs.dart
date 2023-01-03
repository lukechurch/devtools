// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../shared/analytics/constants.dart' as gac;
import '../../shared/common_widgets.dart';
import '../../shared/primitives/simple_items.dart';
import '../../shared/ui/tab.dart';
import 'memory_controller.dart';
import 'panes/allocation_profile/allocation_profile_table_view.dart';
import 'panes/allocation_tracing/allocation_profile_tracing_view.dart';
import 'panes/diff/diff_pane.dart';
import 'panes/leaks/leaks_pane.dart';

class MemoryScreenKeys {
  static const leaksTab = Key(WidgetIds.leaksTab);
  static const dartHeapTableProfileTab = Key(WidgetIds.dartHeapTableProfileTab);
  static const dartHeapAllocationTracingTab =
      Key(WidgetIds.dartHeapAllocationTracingTab);
  static const diffTab = Key(WidgetIds.diffTab);
}

class MemoryTabView extends StatefulWidget {
  const MemoryTabView(this.controller, {super.key});

  static const _gaPrefix = 'memoryTab';

  final MemoryController controller;

  @override
  State<StatefulWidget> createState() => MemoryTabViewState();
}

class MemoryTabViewState extends State<MemoryTabView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.shouldShowLeaksTab,
      builder: (context, showLeaksTab, _) {
        final tabRecords = _generateTabRecords();
        final tabs = <DevToolsTab>[];
        final tabViews = <Widget>[];
        for (final record in tabRecords) {
          tabs.add(record.tab);
          tabViews.add(record.tabView);
        }
        return AnalyticsTabbedView(
          tabs: tabs,
          tabViews: tabViews,
          initialSelectedIndex: widget.controller.selectedFeatureTabIndex,
          gaScreen: gac.memory,
          selectedTabNotifier: widget.controller.currentTab,
          onTabChanged: (int index) {
            widget.controller.selectedFeatureTabIndex = index;
          },
        );
      },
    );
  }

  List<TabRecord> _generateTabRecords() {
    return [
      TabRecord(
        tab: DevToolsTab.create(
          key: MemoryScreenKeys.dartHeapTableProfileTab,
          tabName: 'Profile',
          gaPrefix: MemoryTabView._gaPrefix,
        ),
        tabView: KeepAliveWrapper(
          child: AllocationProfileTableView(
            controller: widget.controller.allocationProfileController,
          ),
        ),
      ),
      TabRecord(
        tab: DevToolsTab.create(
          key: MemoryScreenKeys.diffTab,
          gaPrefix: MemoryTabView._gaPrefix,
          tabName: 'Diff',
        ),
        tabView: KeepAliveWrapper(
          child: DiffPane(
            diffController: widget.controller.diffPaneController,
          ),
        ),
      ),
      TabRecord(
        tab: DevToolsTab.create(
          key: MemoryScreenKeys.dartHeapAllocationTracingTab,
          tabName: 'Trace',
          gaPrefix: MemoryTabView._gaPrefix,
        ),
        tabView: const KeepAliveWrapper(
          child: AllocationProfileTracingView(),
        ),
      ),
      if (widget.controller.shouldShowLeaksTab.value)
        TabRecord(
          tab: DevToolsTab.create(
            key: MemoryScreenKeys.leaksTab,
            gaPrefix: MemoryTabView._gaPrefix,
            tabName: 'Detect Leaks',
          ),
          tabView: const KeepAliveWrapper(child: LeaksPane()),
        ),
    ];
  }
}
