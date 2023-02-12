// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../devtools_app.dart';

mixin HighlightableMixin on StatefulWidget {
  final isHighlighted = ValueNotifier<bool>(false);

  void toggleIsHighlighted(
    bool value, {
    Duration? duration = const Duration(seconds: 3),
  }) {
    if (key == null) return;

    isHighlighted.value = value;
    if (duration == null) return;
    Timer(duration, () {
      isHighlighted.value = !value;
    });
  }
}

mixin HighlightableStateMixin<T extends StatefulWidget> on State<T>
    implements SingleTickerProviderStateMixin<T>, AutoDisposeMixin<T> {
  late AnimationController controller;
  late Animation<Color?> animation;

  VoidCallback? _isHighlightedListener;

  void initHighlightableState() {
    if (widget.key == null) return;

    discoverableApp.highlightableElements[widget.key!] = this;
    _initAnimationController();
    _initIsHighlightedListener();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget as HighlightableMixin).isHighlighted !=
        (widget as HighlightableMixin).isHighlighted) {
      _initIsHighlightedListener();
    }
  }

  void _initAnimationController() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final CurvedAnimation curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    animation = ColorTween(
      end: Colors.red,
      begin: Colors.white,
    ).animate(curve);

    addAutoDisposeListener(animation, () {
      if (!(widget as HighlightableMixin).isHighlighted.value) return;
      if (animation.status == AnimationStatus.completed) {
        controller.reverse();
      } else if (animation.status == AnimationStatus.dismissed) {
        controller.forward();
      }
      setState(() {});
    });
  }

  void _initIsHighlightedListener() {
    cancelListener(_isHighlightedListener);
    _isHighlightedListener = () {
      setState(() {
        if ((widget as HighlightableMixin).isHighlighted.value) {
          controller.reset();
          controller.forward();
          return;
        }
        controller.reset();
      });
    };
    addAutoDisposeListener(
      (widget as HighlightableMixin).isHighlighted,
      _isHighlightedListener,
    );
  }

  void disposeHighlightableState() {
    if (widget.key == null) return;

    controller.dispose();
    discoverableApp.highlightableElements.remove(widget.key);
    super.dispose();
  }
}
