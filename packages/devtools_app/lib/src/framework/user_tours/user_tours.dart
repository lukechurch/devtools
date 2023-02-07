// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../shared/config_specific/launch_url/launch_url.dart';
import '../../shared/globals.dart';
import '../../shared/primitives/auto_dispose.dart';
import '../../shared/primitives/simple_items.dart';
import '../../shared/theme.dart';

class UserToursViewer extends StatefulWidget {
  const UserToursViewer({super.key, required this.child});

  final Widget child;

  @override
  _UserToursViewerState createState() => _UserToursViewerState();
}

class _UserToursViewerState extends State<UserToursViewer>
    with AutoDisposeMixin, SingleTickerProviderStateMixin {
  /// Animation controller for animating the opening and closing of the viewer.
  late AnimationController visibilityController;

  /// A curved animation that matches [visibilityController].
  late Animation<double> visibilityAnimation;

  String? markdownData;

  late bool isVisible;

  late UserToursController userToursController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userToursController = Provider.of<UserToursController>(context);

    isVisible = userToursController.userToursVisible.value;
    markdownData = userToursController.userToursMarkdown.value;

    visibilityController = longAnimationController(this);
    visibilityAnimation =
        Tween<double>(begin: 0, end: 1.0).animate(visibilityController);

    addAutoDisposeListener(userToursController.userToursVisible, () {
      setState(() {
        isVisible = userToursController.userToursVisible.value;
        if (isVisible) {
          visibilityController.forward();
        } else {
          visibilityController.reverse();
        }
      });
    });

    markdownData = userToursController.userToursMarkdown.value;
    addAutoDisposeListener(userToursController.userToursMarkdown, () {
      setState(() {
        markdownData = userToursController.userToursMarkdown.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return UserToursViewerAnimated(
      userToursController: userToursController,
      markdownData: markdownData,
      visibilityAnimation: visibilityAnimation,
      child: widget.child,
    );
  }
}

class UserToursViewerAnimated extends AnimatedWidget {
  UserToursViewerAnimated({
    Key? key,
    required this.userToursController,
    required this.markdownData,
    required this.child,
    required Animation<double> visibilityAnimation,
  }) : super(key: key, listenable: visibilityAnimation);

  final UserToursController userToursController;

  final String? markdownData;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final width = MediaQuery.of(context).size.width * 0.3;
    final animatedWidth = width * animation.value;
    userToursController._width.value = animatedWidth;

    return Row(
      children: [
        Expanded(
          child: child,
        ),
        SizedBox(
          width: animatedWidth,
          child: Stack(
            children: [
              UserTours(
                userToursController: userToursController,
                markdownData: markdownData,
                visibilityAnimation: animation,
                width: width,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UserTours extends AnimatedWidget {
  const UserTours({
    Key? key,
    required this.userToursController,
    required Animation<double> visibilityAnimation,
    required this.markdownData,
    required this.width,
  }) : super(key: key, listenable: visibilityAnimation);

  final UserToursController userToursController;

  final String? markdownData;

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animation = listenable as Animation<double>;
    final displacement = width * (1 - animation.value);
    final right = densePadding - displacement;

    return Positioned(
      top: densePadding,
      bottom: densePadding,
      right: right,
      width: width,
      child: Card(
        elevation: defaultElevation,
        color: theme.scaffoldBackgroundColor,
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          side: BorderSide(
            color: theme.focusColor,
          ),
        ),
        child: markdownData == null
            ? const Text('No tour available for this screen yet.')
            : Markdown(
                data: markdownData!,
                onTapLink: (_, href, __) {
                  if (href!.startsWith(internalUriScheme)) {
                    unawaited(discoverableApp.handleActionPath(href));
                    return;
                  }
                  unawaited(launchUrl(href));
                },
              ),
      ),
    );
  }
}

class UserToursController {
  UserToursController() {
    _init();
  }

  ValueListenable<String?> get userToursMarkdown => _userToursMarkdown;

  final _userToursMarkdown = ValueNotifier<String?>(null);

  ValueListenable<bool> get userToursVisible => _userToursVisible;

  final _userToursVisible = ValueNotifier<bool>(false);

  final _width = ValueNotifier<double>(0);

  ValueListenable<double> get width => _width;

  void _init() {
    _userToursMarkdown.value = _memoryViewInstructions;
  }

  void toggleUserToursVisible(bool visible) {
    _userToursVisible.value = visible;
  }
}

const String _memoryViewInstructions = '''
# Memory view guide

The DevTools memory view helps you investigate memory allocations (both in the heap and external), memory leaks, memory bloat, and more. The view has the following features:

- [Expandable chart](devtools://memory/toggle_memory_chart_button?action=highlight) - Get a high-level trace of memory allocation, and view both standard events (like garbage collection) and custom events (like image allocation).
- [Profile tab](devtools://memory/Dart%20Heap%20Profile%20Tab?action=highlight) - See current memory allocation listed by class and memory type (Dart or external/native).
- [Diff tab](devtools://memory/Diff%20Tab?action=highlight) - Detect and investigate a feature’s memory management issues.
- [Trace tab](devtools://memory/Dart%20Heap%20Allocation%20Tracing%20Tab?action=highlight) - Investigate a feature’s memory management for a specified set of classes.


## Expandable chart
The expandable chart provides the following features:

### Memory anatomy
A timeseries graph visualizes the state of Flutter memory at successive intervals of time. Each data point on the chart corresponds to the timestamp (x-axis) of measured quantities (y-axis) of the heap. For example, usage, capacity, external, garbage collection, and resident set size are captured.

### Memory overview chart
The memory overview chart is a timeseries graph of collected memory statistics. It visually presents the state of the Dart or Flutter heap and Dart’s or Flutter’s native memory over time.

The chart’s x-axis is a timeline of events (timeseries). The data plotted in the y-axis all has a timestamp of when the data was collected. In other words, it shows the polled state (capacity, used, external, RSS (resident set size), and GC (garbage collection)) of the memory every 500 ms. This helps provide a live appearance on the state of the memory as the application is running.

Clicking the [Legend](devtools://memory/toggle_memory_chart_legend_button?action=highlight) button displays the collected measurements, symbols, and colors used to display the data.


## Profile tab
Use the [Profile](devtools://memory/Dart%20Heap%20Profile%20Tab?action=select,highlight) tab to see current memory allocation by class and memory type. For a deeper analysis in Google Sheets or other tools, download the data in CSV format. Toggle [Refresh on GC](devtools://memory/refresh_on_gc_button?action=highlight), to see allocation in real time.


## Diff tab
Use the [Diff](devtools://memory/Diff%20Tab?action=select,highlight) tab to investigate a feature’s memory management. Follow the guidance on the tab to take snapshots before and after interaction with the application, and diff the snapshots:

[Take a snapshot](devtools://memory/memory_screen_take_snapshot_button?action=highlight), then tap the [Filter classes and packages button](devtools://memory/filter_classes_and_packages_button?action=highlight), to narrow the data:

For a deeper analysis in Google Sheets or other tools, download the data in CSV format.


## Trace tab
Use the [Trace](devtools://memory/Dart%20Heap%20Allocation%20Tracing%20Tab?action=select,highlight) tab to investigate what methods allocate memory for a set of classes during feature execution:

1. Select classes to trace
2. Interact with your app to trigger the code you are interested in
3. Tap [Refresh](devtools://memory/refresh_traces_button?action=highlight)
4. Select a traced class
5. Review the collected data
''';
