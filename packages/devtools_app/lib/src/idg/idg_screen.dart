// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../analytics/analytics.dart' as ga;
import '../auto_dispose_mixin.dart';
import '../common_widgets.dart';
import '../console.dart';
import '../screen.dart';
import '../split.dart';
import '../table.dart';
import '../table_data.dart';
import '../theme.dart';
import '../ui/colors.dart';
import '../ui/filter.dart';
import '../ui/icons.dart';
import '../ui/search.dart';
import '../ui/service_extension_widgets.dart';
import '../utils.dart';
import 'idg_controller.dart';
import 'idg_core.dart' as idg_core;

final loggingSearchFieldKey = GlobalKey(debugLabel: 'LoggingSearchFieldKey');

/// Presents logs from the connected app.
class IDGScreen extends Screen {
  const IDGScreen()
      : super(
          id,
          title: 'IDG',
          icon: Octicons.clippy,
        );

  static const id = 'idg';

  @override
  String get docPageId => screenId;

  @override
  Widget build(BuildContext context) => const IDGScreenBody();

  @override
  Widget buildStatus(BuildContext context, TextTheme textTheme) {
    final IDGController controller = Provider.of<IDGController>(context);

    return StreamBuilder<String>(
      initialData: controller.statusText,
      stream: controller.onLogStatusChanged,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return Text(snapshot.data ?? '');
      },
    );
  }
}

class IDGScreenBody extends StatefulWidget {
  const IDGScreenBody();

  static const filterQueryInstructions = '''
Type a filter query to show or hide specific logs.

Any text that is not paired with an available filter key below will be queried against all categories (kind, message).

Available filters:
    'kind', 'k'       (e.g. 'k:flutter.frame', '-k:gc,stdout')

Example queries:
    'my log message k:stdout,stdin'
    'flutter -k:gc'
''';

  @override
  _IDGScreenState createState() => _IDGScreenState();
}

class _IDGScreenState extends State<IDGScreenBody>
    with AutoDisposeMixin, SearchFieldMixin<IDGScreenBody> {
  LogData selected;

  IDGController controller;

  List<LogData> filteredLogs;

  @override
  void initState() {
    super.initState();
    ga.screen(IDGScreen.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = Provider.of<IDGController>(context);
    if (newController == controller) return;
    controller = newController;

    cancel();

    filteredLogs = controller.filteredData.value;
    addAutoDisposeListener(controller.filteredData, () {
      setState(() {
        filteredLogs = controller.filteredData.value;
      });
    });

    selected = controller.selectedLog.value;
    addAutoDisposeListener(controller.selectedLog, () {
      setState(() {
        selected = controller.selectedLog.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLoggingControls(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildIdgBody(
                  controller.idgEngine.getRecipe(),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: denseRowSpacing),
        Expanded(
          child: _buildLoggingBody(),
        ),
      ],
    );
  }

  Widget _buildLoggingControls() {
    final hasData = controller.filteredData.value.isNotEmpty;
    return Row(
      children: [
        ClearButton(onPressed: controller.clear),
        // const Spacer(),
        // const SizedBox(width: denseSpacing),
        // // TODO(kenz): fix focus issue when state is refreshed
        // Container(
        //   width: wideSearchTextWidth,
        //   height: defaultTextFieldHeight,
        //   child: buildSearchField(
        //     controller: controller,
        //     searchFieldKey: loggingSearchFieldKey,
        //     searchFieldEnabled: hasData,
        //     shouldRequestFocus: false,
        //     supportsNavigation: true,
        //   ),
        // ),
        const SizedBox(width: denseSpacing),
        _idgSelector(),

        // FilterButton(
        // onPressed: _showFilterDialog,
        // isFilterActive: filteredLogs.length != controller.data.length,
        // ),
      ],
    );
  }

  Widget _buildIdgBody(idg_core.Recipe r) {
    List<Widget> widgets = [];

    for (idg_core.Step s in r.steps) {
      widgets.add(
        Row(
          children: [
            Expanded(child: _buildIdgStep(s)),
          ],
        ),
      );
    }

    // return Column(children: [Row(children: widgets)]);

    return ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      children: widgets,
    );

    // return Column(children: [
    //   Row(children: [
    //     Text('IDG Body 1'),
    //     Text('IDG Body 2'),
    //   ]),
    //   Row(children: [
    //     Text('IDG Body 1'),
    //     Text('IDG Body 2'),
    //   ]),
    // ]);
  }

  Widget _buildIdgStep(idg_core.Step s) {
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
              onChanged: (bool value) {
                // TODO -- do more than just setting the step done value
                s.isDone = value;
                setState(() {});
              },
            ),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(
                    child: s.isTitleButton
                        ? ElevatedButton(
                            child: Text(s.title, textScaleFactor: 1.3),
                            onPressed: () {
                              // TODO
                            },
                          )
                        : Padding(
                            padding: EdgeInsets.fromLTRB(16, 13, 16, 13),
                            child: Text(s.title, textScaleFactor: 1.3),
                          ),
                  ),
                ],
              ),
              Row(children: [
                Flexible(
                  child: Text(
                    s.text,
                    softWrap: true,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${s.nextStepGuard.sensorName} : ${s.nextStepGuard.valueString()}',
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
                          onPressed: () {
                            // TODO
                          },
                          child: Text(e),
                        )))
                    .toList(),
              ),
              Row(children: [Text('')]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoggingBody() {
    return Split(
      axis: Axis.vertical,
      initialFractions: const [0.72, 0.28],
      children: [
        OutlineDecoration(
          child: LogsTable(
            data: filteredLogs,
            onItemSelected: controller.selectLog,
            selectionNotifier: controller.selectedLog,
            searchMatchesNotifier: controller.searchMatches,
            activeSearchMatchNotifier: controller.activeSearchMatch,
          ),
        ),
        LogDetails(log: selected),
      ],
    );
  }

  var _runAnApp = "Run an App"; // TODO: Extract to the encoding of a list
  Widget _idgSelector() => DropdownButton<String>(
        items: <String>[_runAnApp, 'Find a memory leak'].map(
          (String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          },
        ).toList(),
        value: _runAnApp,
        onChanged: (_) {}, // TODO: jump to IDG selector
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
    Key key,
    @required this.data,
    @required this.onItemSelected,
    @required this.selectionNotifier,
    @required this.searchMatchesNotifier,
    @required this.activeSearchMatchNotifier,
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
  const LogDetails({Key key, @required this.log}) : super(key: key);

  final LogData log;

  @override
  _LogDetailsState createState() => _LogDetailsState();

  static const copyToClipboardButtonKey =
      Key('log_details_copy_to_clipboard_button');
}

class _LogDetailsState extends State<LogDetails>
    with SingleTickerProviderStateMixin {
  String _lastDetails;
  ScrollController scrollController;

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
    final disabled = log?.details == null || log.details.isEmpty;

    final details = log?.details;
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
    VoidCallback onPressed,
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
      dataObject.summary ?? dataObject.details;

  @override
  int compare(LogData a, LogData b) {
    final String valueA = getValue(a);
    final String valueB = getValue(b);
    // Matches frame descriptions (e.g. '#12  11.4ms ')
    final regex = RegExp(r'#(\d+)\s+\d+.\d+ms\s*');
    final valueAIsFrameLog = valueA.startsWith(regex);
    final valueBIsFrameLog = valueB.startsWith(regex);
    if (valueAIsFrameLog && valueBIsFrameLog) {
      final frameNumberA = regex.firstMatch(valueA)[1];
      final frameNumberB = regex.firstMatch(valueB)[1];
      return int.parse(frameNumberA).compareTo(int.parse(frameNumberB));
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
    VoidCallback onPressed,
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
        final int micros = jsonDecode(data.details)['elapsed'];
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
      return null;
    }
  }
}
