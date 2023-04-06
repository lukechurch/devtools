// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'common_widgets.dart';
import 'primitives/auto_dispose.dart';
import 'theme.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.controller,
    required this.title,
    required this.child,
  });

  final SidebarController controller;

  final String title;
  final Widget child;

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar>
    with AutoDisposeMixin, SingleTickerProviderStateMixin {
  /// Animation controller for animating the opening and closing of the viewer.
  late AnimationController visibilityController;

  /// A curved animation that matches [visibilityController].
  late Animation<double> visibilityAnimation;

  late bool isVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    isVisible = widget.controller.isVisible.value;

    visibilityController = defaultAnimationController(this);
    visibilityAnimation =
        Tween<double>(begin: 0, end: 1.0).animate(visibilityController);

    addAutoDisposeListener(widget.controller.isVisible, () {
      setState(() {
        isVisible = widget.controller.isVisible.value;
        if (isVisible) {
          visibilityController.forward();
        } else {
          visibilityController.reverse();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SidebarAnimated(
      sidebarController: widget.controller,
      visibilityAnimation: visibilityAnimation,
      title: widget.title,
      child: widget.child,
    );
  }
}

class SidebarAnimated extends AnimatedWidget {
  const SidebarAnimated({
    Key? key,
    required this.sidebarController,
    required Animation<double> visibilityAnimation,
    required this.title,
    required this.child,
  }) : super(key: key, listenable: visibilityAnimation);

  final SidebarController sidebarController;

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final width = MediaQuery.of(context).size.width * 0.3;
    final animatedWidth = width * animation.value;
    sidebarController._width.value = animatedWidth;

    final theme = Theme.of(context);
    final displacement = width * (1 - animation.value);
    final right = -densePadding - displacement;

    return SizedBox(
      width: animatedWidth,
      child: Stack(
        children: [
          Positioned(
            top: -densePadding,
            bottom: -densePadding,
            right: right,
            width: width,
            child: Card(
              margin: const EdgeInsets.all(12),
              elevation: defaultElevation,
              color: theme.scaffoldBackgroundColor,
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                side: BorderSide(
                  color: theme.focusColor,
                ),
              ),
              child: Column(
                children: [
                  AreaPaneHeader(
                    title: Text(title),
                    includeTopBorder: false,
                    actions: [
                      IconButton(
                        padding: const EdgeInsets.all(0.0),
                        onPressed: () =>
                            sidebarController.toggleVisibility(false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarController {
  ValueListenable<double> get width => _width;
  final _width = ValueNotifier<double>(0);

  ValueListenable<bool> get isVisible => _isVisible;
  final _isVisible = ValueNotifier<bool>(false);

  void toggleVisibility(bool visible) {
    _isVisible.value = visible;
  }
}
