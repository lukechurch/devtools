// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

import 'common_widgets.dart';
import 'config_specific/launch_url/launch_url.dart';
import 'globals.dart';
import 'primitives/auto_dispose.dart';
import 'primitives/simple_items.dart';
import 'theme.dart';

const debugTestEdgePanel = false;

class EdgePanelViewer extends StatefulWidget {
  const EdgePanelViewer({
    Key? key,
    required this.controller,
    required this.title,
    required this.child,
  }) : super(key: key);

  final EdgePanelController controller;
  final String? title;
  final Widget? child;

  @override
  _EdgePanelViewerState createState() => _EdgePanelViewerState();
}

class _EdgePanelViewerState extends State<EdgePanelViewer>
    with AutoDisposeMixin, SingleTickerProviderStateMixin {
  static const maxViewerWidth = 600.0;

  /// Animation controller for animating the opening and closing of the viewer.
  late AnimationController visibilityController;

  /// A curved animation that matches [visibilityController].
  late Animation<double> visibilityAnimation;

  String? markdownData;

  late bool isVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isVisible = widget.controller.edgePanelVisible.value;
    markdownData = widget.controller.edgePanelMarkdown.value;

    visibilityController = longAnimationController(this);
    visibilityAnimation =
        Tween<double>(begin: 1.0, end: 0).animate(visibilityController);

    addAutoDisposeListener(widget.controller.edgePanelVisible, () {
      setState(() {
        isVisible = widget.controller.edgePanelVisible.value;
        if (isVisible) {
          visibilityController.forward();
        } else {
          visibilityController.reverse();
        }
      });
    });

    markdownData = widget.controller.edgePanelMarkdown.value;
    addAutoDisposeListener(widget.controller.edgePanelMarkdown, () {
      setState(() {
        markdownData = widget.controller.edgePanelMarkdown.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Material(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthForSmallScreen = constraints.maxWidth - 2 * densePadding;
          final width = min(
            _EdgePanelViewerState.maxViewerWidth,
            widthForSmallScreen,
          );
          return Stack(
            children: [
              if (child != null) child,
              EdgePanel(
                edgePanelController: widget.controller,
                visibilityAnimation: visibilityAnimation,
                title: widget.title,
                markdownData: markdownData,
                width: width,
              ),
            ],
          );
        },
      ),
    );
  }
}

class EdgePanel extends AnimatedWidget {
  const EdgePanel({
    Key? key,
    required this.edgePanelController,
    required Animation<double> visibilityAnimation,
    required this.title,
    required this.markdownData,
    required this.width,
  }) : super(key: key, listenable: visibilityAnimation);

  final EdgePanelController edgePanelController;

  final String? title;

  final String? markdownData;

  final double width;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final theme = Theme.of(context);
    final displacement = width * animation.value;
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
        child: Column(
          children: [
            AreaPaneHeader(
              title: Text(title ?? ''),
              needsTopBorder: false,
              actions: [
                IconButton(
                  padding: const EdgeInsets.all(0.0),
                  onPressed: () =>
                      edgePanelController.toggleEdgePanelVisible(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: Markdown(
                data: markdownData ?? '',
                onTapLink: (_, href, __) {
                  if (href!.startsWith(internalUriScheme)) {
                    unawaited(discoverableApp.handleActionPath(href));
                    return;
                  }
                  unawaited(launchUrl(href));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class EdgePanelController {
  ValueListenable<String?> get edgePanelMarkdown => _edgePanelMarkdown;

  final _edgePanelMarkdown = ValueNotifier<String?>(null);

  ValueListenable<bool> get edgePanelVisible => _edgePanelVisible;

  final _edgePanelVisible = ValueNotifier<bool>(false);

  void toggleEdgePanelVisible(bool visible) {
    _edgePanelVisible.value = visible;
  }

  String get _flutterDocsSite => debugTestEdgePanel
      ? 'https://flutter-website-dt-staging.web.app'
      : 'https://docs.flutter.dev';

  static const _unsupportedPathSyntax = '{{site.url}}';

  String _replaceUnsupportedPathSyntax(String markdownText) {
    // This is a workaround so that the images in the edge panel will appear.
    // The {{site.url}} syntax is best practices for the flutter website
    // repo, where these release notes are hosted, so we are performing this
    // workaround on our end to ensure the images render properly.
    return markdownText.replaceAll(
      _unsupportedPathSyntax,
      _flutterDocsSite,
    );
  }
}

class EdgePanelControllerMarkdownUrl extends EdgePanelController {
  EdgePanelControllerMarkdownUrl(
    String markdownFileName,
  ) {
    unawaited(_fetchEdgePanel(markdownFileName));
  }

  set edgePanelMarkdownFileName(String markdownFileName) {
    unawaited(_fetchEdgePanel(markdownFileName));
  }

  final String _devtoolsDocsFolder = 'development/tools/devtools';

  Future<void> _fetchEdgePanel(markdownFileName) async {
    final edgePanelMarkdown = await http.read(
      Uri.parse('$_flutterDocsSite/$_devtoolsDocsFolder/$markdownFileName'),
    );
    _edgePanelMarkdown.value = _replaceUnsupportedPathSyntax(edgePanelMarkdown);
  }
}

class EdgePanelControllerMarkdownString extends EdgePanelController {
  EdgePanelControllerMarkdownString(
    String markdownText,
  ) {
    _edgePanelMarkdown.value = _replaceUnsupportedPathSyntax(markdownText);
  }

  set edgePanelMarkdownText(String markdownText) {
    _edgePanelMarkdown.value = _replaceUnsupportedPathSyntax(markdownText);
  }
}
