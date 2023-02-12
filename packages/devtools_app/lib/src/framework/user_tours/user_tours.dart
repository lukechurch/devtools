// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../shared/config_specific/launch_url/launch_url.dart';
import '../../shared/edge_panel.dart';
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

    isVisible = userToursController.isVisible.value;
    markdownData = userToursController.markdown.value;

    visibilityController = longAnimationController(this);
    visibilityAnimation =
        Tween<double>(begin: 0, end: 1.0).animate(visibilityController);

    addAutoDisposeListener(userToursController.isVisible, () {
      setState(() {
        isVisible = userToursController.isVisible.value;
        if (isVisible) {
          visibilityController.forward();
        } else {
          visibilityController.reverse();
        }
      });
    });

    markdownData = userToursController.markdown.value;
    addAutoDisposeListener(userToursController.markdown, () {
      setState(() {
        markdownData = userToursController.markdown.value;
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

class UserToursController extends EdgePanelControllerMarkdownUrl {
  UserToursController(String markdownFileName) : super(markdownFileName);

  final _width = ValueNotifier<double>(0);

  ValueListenable<double> get width => _width;
}
