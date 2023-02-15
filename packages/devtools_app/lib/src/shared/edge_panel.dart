// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
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

const debugTestEdgePanel = true;

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
    isVisible = widget.controller.isVisible.value;
    markdownData = widget.controller.markdown.value;

    visibilityController = longAnimationController(this);
    visibilityAnimation =
        Tween<double>(begin: 1.0, end: 0).animate(visibilityController);

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

    markdownData = widget.controller.markdown.value;
    addAutoDisposeListener(widget.controller.markdown, () {
      setState(() {
        markdownData = widget.controller.markdown.value;
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
                  onPressed: () => edgePanelController.toggleVisibility(false),
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
  ValueListenable<String?> get markdown => _markdown;

  final _markdown = ValueNotifier<String?>(null);

  ValueListenable<bool> get isVisible => _isVisible;

  final _isVisible = ValueNotifier<bool>(false);

  void toggleVisibility(bool visible) {
    _isVisible.value = visible;
  }

  String get _flutterDocsSite =>
      debugTestEdgePanel ? 'http://localhost:4002' : 'https://docs.flutter.dev';

  static const _unsupportedPathSyntax = '{{site.url}}';

  String _replaceUnsupportedPathSyntax(String markdownText) {
    // This is a workaround so that the images will appear and links will
    // point to the right links on the website.
    // The {{site.url}} syntax is best practices for the flutter website
    // repo, where these release notes are hosted, so we are performing this
    // workaround on our end to ensure the images render properly.
    markdownText = markdownText.replaceAll(
      _unsupportedPathSyntax,
      _flutterDocsSite,
    );

    // This is a workaround so that any CSS formatting applied to images and
    // links on the flutter website can be ignored in devtools.
    // TODO: The regex is too simplistic, needs fixing to do bracket balancing for nested brackets.
    markdownText = markdownText.replaceAll(RegExp('\\{:(.*?)\\}'), '');

    return markdownText;
  }
}

class EdgePanelControllerMarkdownUrl extends EdgePanelController {
  EdgePanelControllerMarkdownUrl(
    String markdownFileName,
  ) {
    unawaited(_fetchMarkdownContents(markdownFileName));
  }

  set markdownFileName(String markdownFileName) {
    unawaited(_fetchMarkdownContents(markdownFileName));
  }

  final String _devtoolsDocsFolder = 'development/tools/devtools';

  Future<void> _fetchMarkdownContents(markdownFileName) async {
    var markdownText = await http.read(
      Uri.parse('$_flutterDocsSite/$_devtoolsDocsFolder/$markdownFileName'),
    );
    if (markdownFileName == 'memory-src.md') {
      markdownText = '# Using the Memory view\n\n$markdownText';
    }
    final utf8Markdown = utf8.decode(markdownText.runes.toList());
    _markdown.value = _replaceUnsupportedPathSyntax(utf8Markdown);
  }
}

class EdgePanelControllerMarkdownString extends EdgePanelController {
  EdgePanelControllerMarkdownString(
    String markdownText,
  ) {
    _markdown.value = _replaceUnsupportedPathSyntax(markdownText);
  }

  set markdownText(String markdownText) {
    _markdown.value = _replaceUnsupportedPathSyntax(markdownText);
  }
}
