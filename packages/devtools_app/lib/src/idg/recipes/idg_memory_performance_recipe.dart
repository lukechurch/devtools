import 'dart:async';

import '../../../devtools_app.dart' as devtools_app;
import '../../shared/globals.dart';
import '../../shared/table.dart';
import '../idg_controller.dart';
import '../idg_core.dart' as idg_core;

var _s0 = idg_core.Step(
  title: 'Open the Memory tab',
  text: '''
      After DevTools has connected to the running Flutter application, click on
      the Memory tab or click the button below''',
  nextStepGuard: idg_core.CondOr(
    () => devtools_app.selectedPage == devtools_app.MemoryScreen.id,
    idg_core.PresenceSensor(
      'DevToolsRouter.navigateTo.memory',
      'Memory tab selected',
    ),
  ),
  buttons: [
    idg_core.Action('go to Memory tab', () async {
      print('go to Memory tab button clicked');
      frameworkController.notifyShowPageId(devtools_app.MemoryScreen.id);
    })
  ],
);

var _s1 = idg_core.Step(
  title: 'Take a memory snapshot',
  text: '''
      Press the Snapshot button to collect information about all objects in the
      Dart VM Heap''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/readme_images/table_first.png',
  nextStepGuard: idg_core.MaskUntil(
    () => _s0.isDone,
    idg_core.PresenceSensor('mem-snapshot', 'snapshot taken'),
  ),
  buttons: [
    idg_core.Action('Show me the Snapshot button', () async {
      final devtools_app.MemoryController memoryScreenController =
          globals[devtools_app.MemoryController];
      memoryScreenController.toggleSnapshotButtonHighlighted(true);
      Timer(
        const Duration(milliseconds: 300),
        () => memoryScreenController.toggleSnapshotButtonHighlighted(false),
      );
      Timer(
        const Duration(milliseconds: 600),
        () => memoryScreenController.toggleSnapshotButtonHighlighted(true),
      );
      Timer(
        const Duration(milliseconds: 900),
        () => memoryScreenController.toggleSnapshotButtonHighlighted(false),
      );
    })
  ],
);

var _s2 = idg_core.Step(
  title: 'Open and explore the snapshot',
  text: '''
      The analysis collects the raw memory objects that contain external objects
      (such as images) under 
      > Analyzed MMM DD HH:MM:SS
          > Externals
              > _Image
                  > Buckets
      
      If your app is using images, it may also be worth investigating the the
      number objects in the ImageCache (pending, cache, and live images):
      > Analyzed MMM DD HH:MM:SS
          > Library filters
              > ImageCache
      
      It can also be useful to look at the other class data collected by the
      snapshot, such as the number of objects from each class and their size:
      > Snapshot MMM DD HH:MM:SS
          > src

      When you're ready and you have explored the snapshot, click done.
      ''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
    idg_core.PresenceSensor('next-step-ready', 'ready for next step'),
  ),
  buttons: [
    _generateExpandAnalysisExternals(),
    _generateExpandAnalysisLibraryFilters(),
    _generateExpandSnapshotSrc(),
    idg_core.Action('done', () async {
      final IDGController idgController = globals[IDGController];
      idgController.log(
        LogData(
          'next-step-ready',
          '',
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
    })
  ],
);

var _s3 = idg_core.Step(
  title: 'Use your app',
  text: '''
      Use your app for a while to create more objects.
      
      When you're done and you notice the app slowing down, or the memory graph
      indicates high memory usage, take another snapshot.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s2.isDone,
    idg_core.PresenceSensor('mem-snapshot', 'snapshot taken'),
  ),
  buttons: [
    idg_core.Action('Show me the Snapshot button', () async {
      final devtools_app.MemoryController memoryScreenController =
          globals[devtools_app.MemoryController];
      memoryScreenController.toggleSnapshotButtonHighlighted(true);
      Timer(
        const Duration(milliseconds: 300),
        () => memoryScreenController.toggleSnapshotButtonHighlighted(false),
      );
      Timer(
        const Duration(milliseconds: 600),
        () => memoryScreenController.toggleSnapshotButtonHighlighted(true),
      );
      Timer(
        const Duration(milliseconds: 900),
        () => memoryScreenController.toggleSnapshotButtonHighlighted(false),
      );
    })
  ],
);

var _s4 = idg_core.Step(
  title: 'Analyse the second snapshot',
  text: '''
      Check again the analysis externals and library filters, and the snapshot
      source. 
      
      Where are the largest differences from the previous snapshot?''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s3.isDone,
    idg_core.PresenceSensor('img-buckets-expanded', 'Externals expanded'),
  ),
  buttons: [
    _generateExpandAnalysisExternals(),
    _generateExpandAnalysisLibraryFilters(),
    _generateExpandSnapshotSrc(),
  ],
);

final memoryPerfRecipe = idg_core.Recipe(
  <idg_core.Step>[_s0, _s1, _s2, _s3, _s4],
);

idg_core.Action _generateExpandAnalysisExternals() =>
    idg_core.Action('Expand Analysis > Externals', () async {
      print('expanding Externals > _Image');

      final devtools_app.MemoryController memoryScreenController =
          globals[devtools_app.MemoryController];
      final lastAnalysis = memoryScreenController
          .lastSnapshot!.controller.completedAnalyses.last;
      lastAnalysis.expand();

      final externalsNode = lastAnalysis.children
          .singleWhere((element) => element.name == 'Externals');
      externalsNode.expand();

      final imageNode = externalsNode.children
          .singleWhere((element) => element.name == '_Image');
      imageNode.expandCascading();

      // Select the _Image node
      imageNode.select();
      memoryScreenController.selectionSnapshotNotifier.value = Selection(
        node: imageNode,
        nodeIndex: imageNode.index,
        scrollIntoView: true,
      );

      // Let the IDG engine know that the node has been expanded
      final IDGController idgController = globals[IDGController];
      idgController.log(
        LogData(
          'img-buckets-expanded',
          '',
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });

idg_core.Action _generateExpandAnalysisLibraryFilters() =>
    idg_core.Action('Expand Analysis > Library filters', () async {
      print('expanding Externals > _Images');

      final devtools_app.MemoryController memoryScreenController =
          globals[devtools_app.MemoryController];
      final lastAnalysis = memoryScreenController
          .lastSnapshot!.controller.completedAnalyses.last;
      lastAnalysis.expand();

      final libraryFiltersNode = lastAnalysis.children
          .singleWhere((element) => element.name == 'Library filters');
      libraryFiltersNode.expand();

      final imageCacheNode = libraryFiltersNode.children
          .singleWhere((element) => element.name == 'ImageCache');
      imageCacheNode.expand();

      // Select the _Image node
      imageCacheNode.select();
      memoryScreenController.selectionSnapshotNotifier.value = Selection(
        node: imageCacheNode,
        nodeIndex: imageCacheNode.index,
        scrollIntoView: true,
      );

      // Let the IDG engine know that the node has been expanded
      final IDGController idgController = globals[IDGController];
      idgController.log(
        LogData(
          'lib-filters-expanded',
          '',
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });

idg_core.Action _generateExpandSnapshotSrc() =>
    idg_core.Action('Expand Snapshot > src', () async {
      print('expanding Snapshot > src');

      final devtools_app.MemoryController memoryScreenController =
          globals[devtools_app.MemoryController];
      final lastSnapshot = memoryScreenController.activeSnapshot;
      lastSnapshot.expand();

      final srcNode =
          lastSnapshot.children.singleWhere((element) => element.name == 'src');
      srcNode.expand();

      srcNode.select();
      memoryScreenController.selectionSnapshotNotifier.value = Selection(
        node: srcNode,
        nodeIndex: srcNode.index,
        scrollIntoView: true,
      );

      // Let the IDG engine know that the node has been expanded
      final IDGController idgController = globals[IDGController];
      idgController.log(
        LogData(
          'lib-filters-expanded',
          '',
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
