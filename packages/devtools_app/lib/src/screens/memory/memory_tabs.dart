// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../shared/analytics/constants.dart' as gac;
import '../../shared/common_widgets.dart';
import '../../shared/primitives/simple_items.dart';
import '../../shared/ui/tab.dart';
import 'memory_controller.dart';
import 'panes/diff/diff_pane.dart';
import 'panes/leaks/leaks_pane.dart';
import 'panes/profile/profile_view.dart';
import 'panes/tracing/tracing_view.dart';

class MemoryTabView extends StatelessWidget {
  const MemoryTabView(
    this.controller,
  );

  static const _gaPrefix = 'memoryTab';

  final MemoryController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.shouldShowLeaksTab,
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
          initialSelectedIndex: controller.selectedFeatureTabIndex,
          gaScreen: gac.memory,
          selectedTabNotifier: controller.currentTab,
          onTabChanged: (int index) {
            controller.selectedFeatureTabIndex = index;
          },
        );
      },
    );
  }

  List<TabRecord> _generateTabRecords() {
    return [
      TabRecord(
        tab: DevToolsTab.create(
          key: Key(WidgetKeys.dartHeapTableProfileTab.id),
          tabName: 'Profile Memory',
          gaPrefix: _gaPrefix,
        ),
        tabView: KeepAliveWrapper(
          child: AllocationProfileTableView(
            controller: controller.controllers.profile,
          ),
        ),
      ),
      TabRecord(
        tab: DevToolsTab.create(
          key: Key(WidgetKeys.diffTab.id),
          gaPrefix: _gaPrefix,
          tabName: 'Diff Snapshots',
        ),
        tabView: KeepAliveWrapper(
          child: DiffPane(
            diffController: controller.controllers.diff,
          ),
        ),
      ),
      TabRecord(
        tab: DevToolsTab.create(
          key: Key(WidgetKeys.dartHeapAllocationTracingTab.id),
          tabName: 'Trace Instances',
          gaPrefix: _gaPrefix,
        ),
        tabView: KeepAliveWrapper(
          child: TracingPane(controller: controller.controllers.tracing),
        ),
      ),
      if (controller.shouldShowLeaksTab.value)
        TabRecord(
          tab: DevToolsTab.create(
            key: Key(WidgetKeys.leaksTab.id),
            gaPrefix: _gaPrefix,
            tabName: 'Detect Leaks',
          ),
          tabView: const KeepAliveWrapper(child: LeaksPane()),
        ),
    ];
  }
}
