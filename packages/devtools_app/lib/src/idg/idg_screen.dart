// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';

import '../primitives/auto_dispose_mixin.dart';
import '../shared/common_widgets.dart';
import '../shared/theme.dart';
import '../ui/search.dart';
import 'idg_controller.dart';
import 'idg_core.dart' as idg_core;
import 'idg_recipes.dart';

final loggingSearchFieldKey = GlobalKey(debugLabel: 'LoggingSearchFieldKey');

final idgRecipes = {
  'Find a memory leak': oomCaseStudyRecipe,
  'Report an issue': openGithubIssueRecipe,
  // 'Minimal Recipe': minimalRecipe,
};

class IDGScreen extends StatefulWidget {
  const IDGScreen({
    Key? key,
    required this.idgController,
    required this.child,
  }) : super(key: key);

  final IDGController idgController;

  final Widget child;

  @override
  _IDGScreenState createState() => _IDGScreenState();
}

class _IDGScreenState extends State<IDGScreen>
    with AutoDisposeMixin, SingleTickerProviderStateMixin {
  static const viewerWidth = 600.0;

  /// Animation controller for animating the opening and closing of the viewer.
  late AnimationController visibilityController;

  /// A curved animation that matches [visibilityController].
  late Animation<double> visibilityAnimation;

  late bool isVisible;

  @override
  void initState() {
    super.initState();
    isVisible = widget.idgController.idgVisible.value;

    visibilityController = longAnimationController(this);
    // Add [densePadding] to the end to account for the space between the
    // release notes viewer and the right edge of DevTools.
    visibilityAnimation =
        Tween<double>(begin: 0, end: viewerWidth + densePadding)
            .animate(visibilityController);

    addAutoDisposeListener(widget.idgController.idgVisible, () {
      setState(() {
        isVisible = widget.idgController.idgVisible.value;
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
    return Material(
      child: Stack(
        children: [
          widget.child,
          IDGBody(
            idgController: widget.idgController,
            visibilityAnimation: visibilityAnimation,
          ),
        ],
      ),
    );
  }
}

class IDGBody extends AnimatedWidget {
  const IDGBody({
    Key? key,
    required this.idgController,
    required Animation<double> visibilityAnimation,
  }) : super(key: key, listenable: visibilityAnimation);

  final IDGController idgController;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final theme = Theme.of(context);
    return Positioned(
      top: densePadding,
      bottom: densePadding,
      right: densePadding - (_IDGScreenState.viewerWidth - animation.value),
      width: _IDGScreenState.viewerWidth,
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
              title: const Text('IDG'),
              needsTopBorder: false,
              rightActions: [
                IconButton(
                  padding: const EdgeInsets.all(0.0),
                  onPressed: () => idgController.toggleIDGVisible(false),
                  icon: const Icon(Icons.arrow_right_alt),
                ),
              ],
            ),
            IDGScreenBody(idgController: idgController),
          ],
        ),
      ),
    );
  }
}

class IDGScreenBody extends StatefulWidget {
  const IDGScreenBody({
    Key? key,
    required this.idgController,
  }) : super(key: key);

  final IDGController idgController;

  @override
  _IDGScreenBodyState createState() =>
      _IDGScreenBodyState(idgController: idgController);
}

class _IDGScreenBodyState extends State<IDGScreenBody>
    with AutoDisposeMixin, SearchFieldMixin<IDGScreenBody> {
  _IDGScreenBodyState({required this.idgController}) : super();

  late final IDGController idgController;

  late LogData selected;

  late List<LogData> filteredLogs;

  Set<idg_core.Step> manualOpened = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: idgController.onEngineUpdated as Stream<bool>,
      builder: (context, snapshot) => Expanded(
        child: _buildIdgBody(idgController.idgEngine.getRecipe()),
      ),
    );
  }

  Widget _buildIdgBody(idg_core.Recipe r) {
    return ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      children: [
        _idgSelector(),
        ExpansionPanelList(
          children: r.steps.map((s) {
            return ExpansionPanel(
              headerBuilder: (context, isExpanded) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(
                        Icons.arrow_right,
                        color: s.isActive ? Colors.green : Colors.transparent,
                        size: 24,
                      ),
                    ),
                    Stack(
                      children: [
                        Checkbox(
                          value: s.isDone,
                          onChanged: (bool? value) {
                            // TODO -- do more than just setting the step done value
                            // s.isDone = value;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: s.isTitleButton
                                ? ElevatedButton(
                                    child: Text(s.title!, textScaleFactor: 1.3),
                                    onPressed: () {
                                      // TODO
                                    },
                                  )
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      13,
                                      16,
                                      13,
                                    ),
                                    child: Text(s.title!, textScaleFactor: 1.3),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              body: _buildIdgStep(s),
              isExpanded: manualOpened.contains(s) || s.isActive,
              canTapOnHeader: true,
            );
          }).toList(),
          expansionCallback: (int i, bool expanded) {
            setState(() {
              print('callback: $i $expanded');
              final idg_core.Step s = r.steps[i];
              if (manualOpened.contains(s))
                manualOpened.remove(s);
              else
                manualOpened.add(s);
            });
          },
        )
      ],
    );
  }

  Widget _buildIdgStep(idg_core.Step s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.text!,
                        softWrap: true,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                if (s.imageUrl != null)
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          constraints: (s.imageMaxHeight != null)
                              ? BoxConstraints(
                                  maxHeight: s.imageMaxHeight!,
                                )
                              : const BoxConstraints(),
                          child: Image.file(
                            File(s.imageUrl!),
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${s.nextStepGuard!.presentationName} : ${s.nextStepGuard!.valueString()}',
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        fontFamily: 'courier',
                      ),
                    )
                  ],
                ),
                Row(
                  children: s.buttons
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              await e.onClick();
                            },
                            child: Text(e.name),
                          ),
                        ),
                      )
                      .toList(),
                ),
                Row(children: const [Text('')]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _idgSelector() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButton<String>(
          items: idgRecipes.keys.map(
            (String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(value),
                ),
              );
            },
          ).toList(),
          value: idgController.idgEngine.selectedRecipe,
          onChanged: (newValue) {
            idgController.idgEngine.selectRecipe(newValue!);
          },
        ),
      );
}
