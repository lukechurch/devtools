// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../devtools_app.dart' hide LogData, timeFormat;
import '../analytics/analytics.dart' as ga;
import '../primitives/auto_dispose_mixin.dart';
import '../shared/common_widgets.dart';
import '../shared/console.dart';
import '../shared/screen.dart';
import '../shared/split.dart';
import '../shared/table.dart';
import '../shared/table_data.dart';
import '../shared/theme.dart';
import '../ui/colors.dart';
import '../ui/filter.dart';
import '../ui/icons.dart';
import '../ui/search.dart';
import '../ui/service_extension_widgets.dart';
import '../shared/utils.dart';
import 'idg_controller.dart';
import 'idg_core.dart' as idg_core;
import 'idg_recipes.dart';

final loggingSearchFieldKey = GlobalKey(debugLabel: 'LoggingSearchFieldKey');

final idgRecipes = {
  'Find a memory leak': oomCaseStudyRecipe,
  'Minimal Recipe': minimalRecipe,
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
                        padding: EdgeInsets.only(top: 12),
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
                                      child:
                                          Text(s.title!, textScaleFactor: 1.3),
                                      onPressed: () {
                                        // TODO
                                      },
                                    )
                                  : Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(16, 13, 16, 13),
                                      child:
                                          Text(s.title!, textScaleFactor: 1.3),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ]);
              },
              body: _buildIdgStep(s),
              isExpanded: manualOpened.contains(s) || s.isActive,
              canTapOnHeader: true,
            );
          }).toList(),
          expansionCallback: (int i, bool expanded) {
            setState(() {
              print("callback: $i $expanded");
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
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      s.text!,
                      softWrap: true,
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ]),
                if (s.imageUrl != null)
                  Row(children: [
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
                  ]),
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
                      .map((e) => Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              await e.onClick();
                            },
                            child: Text(e.name),
                          )))
                      .toList(),
                ),
                Row(children: [Text('')]),
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
  // void _showFilterDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => FilterDialog<IDGController, LogData>(
  //       controller: controller,
  //       queryInstructions: IDGScreenBody.filterQueryInstructions,
  //       queryFilterArguments: controller.filterArgs,
  //     ),
  //   );
  // }
}

class LogsTable extends StatelessWidget {
  LogsTable({
    Key? key,
    required this.data,
    required this.onItemSelected,
    required this.selectionNotifier,
    required this.searchMatchesNotifier,
    required this.activeSearchMatchNotifier,
  }) : super(key: key);

  final List<LogData> data;
  final ItemCallback<LogData> onItemSelected;
  final ValueListenable<LogData> selectionNotifier;
  final ValueListenable<List<LogData>> searchMatchesNotifier;
  final ValueListenable<LogData> activeSearchMatchNotifier;

  final ColumnData<LogData> when = _WhenColumn();
  final ColumnData<LogData> kind = _KindColumn();
  final ColumnData<LogData> message = MessageColumn();

  List<ColumnData<LogData>> get columns => [when, kind, message];

  @override
  Widget build(BuildContext context) {
    return FlatTable<LogData>(
      columns: columns,
      data: data,
      autoScrollContent: true,
      keyFactory: (LogData data) => ValueKey<LogData>(data),
      onItemSelected: onItemSelected,
      selectionNotifier: selectionNotifier,
      sortColumn: when,
      secondarySortColumn: message,
      sortDirection: SortDirection.ascending,
      searchMatchesNotifier: searchMatchesNotifier,
      activeSearchMatchNotifier: activeSearchMatchNotifier,
    );
  }
}

class LogDetails extends StatefulWidget {
  const LogDetails({Key? key, required this.log}) : super(key: key);

  final LogData log;

  @override
  _LogDetailsState createState() => _LogDetailsState();

  static const copyToClipboardButtonKey =
      Key('log_details_copy_to_clipboard_button');
}

class _LogDetailsState extends State<LogDetails>
    with SingleTickerProviderStateMixin {
  late String _lastDetails;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _computeLogDetails();
  }

  @override
  void didUpdateWidget(LogDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.log != oldWidget.log) {
      _computeLogDetails();
    }
  }

  Future<void> _computeLogDetails() async {
    if (widget.log?.needsComputing ?? false) {
      await widget.log.compute();
      setState(() {});
    }
  }

  bool showSimple(LogData log) => log != null && !log.needsComputing;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildContent(context, widget.log),
    );
  }

  Widget _buildContent(BuildContext context, LogData log) {
    // TODO(#1370): Handle showing flutter errors in a structured manner.
    return Stack(
      children: [
        _buildSimpleLog(context, log),
        if (log != null && log.needsComputing)
          const CenteredCircularProgressIndicator(),
      ],
    );
  }

  Widget _buildSimpleLog(BuildContext context, LogData log) {
    final disabled = log?.details == null || log.details!.isEmpty;

    final details = log.details!;
    if (details != _lastDetails) {
      if (scrollController.hasClients) {
        // Make sure we change the scroll if the log details shown have changed.
        scrollController.jumpTo(0);
      }
      _lastDetails = details;
    }

    return OutlineDecoration(
      child: ConsoleFrame(
        title: AreaPaneHeader(
          title: const Text('Details'),
          needsTopBorder: false,
          rightActions: [
            CopyToClipboardControl(
              dataProvider: disabled ? null : () => log?.prettyPrinted,
              buttonKey: LogDetails.copyToClipboardButtonKey,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(denseSpacing),
          child: SingleChildScrollView(
            controller: scrollController,
            child: SelectableText(
              log?.prettyPrinted ?? '',
              textAlign: TextAlign.left,
              style: Theme.of(context).fixedFontStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhenColumn extends ColumnData<LogData> {
  _WhenColumn()
      : super(
          'When',
          fixedWidthPx: scaleByFontFactor(120),
        );

  @override
  bool get supportsSorting => false;

  @override
  String getValue(LogData dataObject) => dataObject.timestamp == null
      ? ''
      : timeFormat
          .format(DateTime.fromMillisecondsSinceEpoch(dataObject.timestamp));
}

class _KindColumn extends ColumnData<LogData>
    implements ColumnRenderer<LogData> {
  _KindColumn()
      : super(
          'Kind',
          fixedWidthPx: scaleByFontFactor(155),
        );

  @override
  bool get supportsSorting => false;

  @override
  String getValue(LogData dataObject) => dataObject.kind;

  @override
  Widget build(
    BuildContext context,
    LogData item, {
    bool isRowSelected = false,
    VoidCallback? onPressed,
  }) {
    final String kind = item.kind;

    Color color = const Color.fromARGB(0xff, 0x61, 0x61, 0x61);

    if (kind == 'stderr' || item.isError || kind == 'flutter.error') {
      color = const Color.fromARGB(0xff, 0xF4, 0x43, 0x36);
    } else if (kind == 'stdout') {
      color = const Color.fromARGB(0xff, 0x78, 0x90, 0x9C);
    } else if (kind.startsWith('flutter')) {
      color = const Color.fromARGB(0xff, 0x00, 0x91, 0xea);
    } else if (kind == 'gc') {
      color = const Color.fromARGB(0xff, 0x42, 0x42, 0x42);
    }

    // Use a font color that contrasts with the colored backgrounds.
    final textStyle = Theme.of(context).fixedFontStyle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Text(
        kind,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }
}

@visibleForTesting
class MessageColumn extends ColumnData<LogData>
    implements ColumnRenderer<LogData> {
  MessageColumn() : super.wide('Message');

  @override
  bool get supportsSorting => false;

  @override
  String getValue(LogData dataObject) =>
      dataObject.summary! ?? dataObject.details!;

  @override
  int compare(LogData a, LogData b) {
    final String valueA = getValue(a);
    final String valueB = getValue(b);
    // Matches frame descriptions (e.g. '#12  11.4ms ')
    final regex = RegExp(r'#(\d+)\s+\d+.\d+ms\s*');
    final valueAIsFrameLog = valueA.startsWith(regex);
    final valueBIsFrameLog = valueB.startsWith(regex);
    if (valueAIsFrameLog && valueBIsFrameLog) {
      final frameNumberA = regex.firstMatch(valueA)![1];
      final frameNumberB = regex.firstMatch(valueB)![1];
      return int.parse(frameNumberA!).compareTo(int.parse(frameNumberB!));
    } else if (valueAIsFrameLog && !valueBIsFrameLog) {
      return -1;
    } else if (!valueAIsFrameLog && valueBIsFrameLog) {
      return 1;
    }
    return valueA.compareTo(valueB);
  }

  @override
  Widget build(
    BuildContext context,
    LogData data, {
    bool isRowSelected = false,
    VoidCallback? onPressed,
  }) {
    TextStyle textStyle = Theme.of(context).fixedFontStyle;
    if (isRowSelected) {
      textStyle = textStyle.copyWith(color: defaultSelectionForegroundColor);
    }

    if (data.kind == 'flutter.frame') {
      const Color color = Color.fromARGB(0xff, 0x00, 0x91, 0xea);
      final Text text = Text(
        getDisplayValue(data),
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );

      double frameLength = 0.0;
      try {
        final int micros = jsonDecode(data.details!)['elapsed'];
        frameLength = micros * 3.0 / 1000.0;
      } catch (e) {
        // ignore
      }

      return Row(
        children: <Widget>[
          text,
          Flexible(
            child: Container(
              height: 12.0,
              width: frameLength,
              decoration: const BoxDecoration(color: color),
            ),
          ),
        ],
      );
    } else if (data.kind == 'stdout') {
      return RichText(
        text: TextSpan(
          children: processAnsiTerminalCodes(
            // TODO(helin24): Recompute summary length considering ansi codes.
            //  The current summary is generally the first 200 chars of details.
            getDisplayValue(data),
            textStyle,
          ),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
