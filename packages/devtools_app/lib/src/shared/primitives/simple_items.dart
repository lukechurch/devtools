// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Package name prefixes.
class PackagePrefixes {
  /// Packages from the core Dart libraries as they are listed
  /// in heap snapshot.
  static const dartInSnapshot = 'dart.';

  /// Packages from the core Dart libraries as they are listed
  /// in import statements.
  static const dart = 'dart:';

  /// Generic dart package.
  static const genericDartPackage = 'package:';

  /// Packages from the core Flutter libraries.
  static const flutterPackage = 'package:flutter/';

  /// The Flutter namespace in C++ that is part of the Flutter Engine code.
  static const flutterEngine = 'flutter::';

  /// dart:ui is the library for the Dart part of the Flutter Engine code.
  static const dartUi = 'dart:ui';
}

enum ScreenMetaData {
  inspector('inspector', 'Flutter Inspector'),
  performance('performance', 'Performance'),
  cpuProfiler('cpu-profiler', 'CPU Profiler'),
  memory('memory', 'Memory'),
  debugger('debugger', 'Debugger'),
  network('network', 'Network'),
  logging('logging', 'Logging'),
  provider('provider', 'Provider'),
  appSize('app-size', 'App Size'),
  vmTools('vm-tools', 'VM Tools'),
  simple('simple', '');

  const ScreenMetaData(this.id, this.title);

  final String id;

  final String title;
}

const String traceEventsFieldName = 'traceEvents';

const String internalUriScheme = 'devtools';
const String internalUriActionQueryKey = 'action';

class WidgetIds {
  WidgetIds._();

  // Elements associated with the memory screen
  static const leaksTab = 'Leaks Tab';
  static const dartHeapTableProfileTab = 'Dart Heap Profile Tab';
  static const dartHeapAllocationTracingTab =
      'Dart Heap Allocation Tracing Tab';
  static const diffTab = 'Diff Tab';

  static const takeSnapshotButton = 'memory_screen_take_snapshot_button';
  static const clearSnapshotsButton = 'memory_screen_clear_snapshots_button';
}

class EventIds {
  EventIds._();

  // Generic events
  static const selectElementEvent = 'select-element';
  static const highlightElementEvent = 'highlight-element';

  static const pageChangedEventPrefix = 'page-changed.';

  // Events triggered by elements on the memory screen
  static const memorySnapshotTakenEvent = 'mem-snapshot-done';
}

class ActionIds {
  ActionIds._();

  // Generic actions
  static const selectElementAction = 'select';
  static const highlightElementAction = 'highlight';

  // Actions associated with the memory screen
  static const takeMemorySnapshotAction = 'take-mem-snapshot';
}
