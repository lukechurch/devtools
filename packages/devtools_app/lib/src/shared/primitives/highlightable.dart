// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../devtools_app.dart';
import '../globals.dart';
import 'auto_dispose.dart';

mixin HighlightableMixin on StatefulWidget {
  final isHighlighted = ValueNotifier<bool>(false);

  void initHighlightable() {
    if (key != null) discoverableApp.highlightableElements[key!] = this;
  }

  void toggleIsHighlighted(
    bool value, {
    Duration? duration = const Duration(seconds: 3),
  }) {
    print('toggling $key');
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

  void initHighlightableState() {
    final highlightableWidget = widget as HighlightableMixin;

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    controller.repeat(reverse: true);
    final CurvedAnimation curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    animation = ColorTween(
      end: Colors.red,
      begin: Colors.white,
    ).animate(curve);

    animation.addStatusListener((status) {
      if (!highlightableWidget.isHighlighted.value) return;
      print('animation status change');
      if (status == AnimationStatus.completed) {
        controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
      setState(() {});
    });

    addAutoDisposeListener(highlightableWidget.isHighlighted, () {
      print('highlightable change');
      setState(() {
        if (highlightableWidget.isHighlighted.value) {
          controller.reset();
          controller.forward();
          return;
        }
        controller.reset();
      });
    });
  }

  void disposeHighlightableState() {
    controller.dispose();
  }
}
