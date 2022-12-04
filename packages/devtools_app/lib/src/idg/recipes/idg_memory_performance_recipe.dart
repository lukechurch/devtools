import '../../../devtools_app.dart';
import '../idg_apis.dart';
import '../idg_core.dart' as idg_core;

var _s0 = idg_core.Step(
  title: 'Open the Memory tab',
  text: '''
      After DevTools has connected to the running Flutter application, click on
      the Memory tab or click the button below''',
  nextStepGuard: idg_core.CondOr(
    () => discoverableApp.selectedPageId == DiscoverableMemoryPage.id,
    idg_core.PresenceSensor(
      'page-changed.memory',
      'Memory tab selected',
    ),
  ),
  buttons: [
    idg_core.Action('go to Memory tab', () async {
      print('go to Memory tab button clicked');
      discoverableApp.selectPage(DiscoverableMemoryPage.id);
    })
  ],
);

var _s1 = idg_core.Step(
  title: 'Take a memory snapshot',
  text: '''
      Press the Snapshot button to collect information about all objects in the
      Dart VM Heap''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1/readme_images/table_first.png',
  nextStepGuard: idg_core.MaskUntil(
    () => _s0.isDone,
    idg_core.PresenceSensor(
      DiscoverableMemoryPage.memorySnapshotTaken,
      'snapshot taken',
    ),
  ),
  buttons: [
    idg_core.Action(
      'Take a snapshot',
      () async => discoverableApp.memoryPage!
        ..changeTabAction(DiscoverableMemoryPage.diffTab)
        ..takeSnapshotAction(),
    ),
  ],
);

var _s2 = idg_core.Step(
  title: 'Open and explore the snapshot',
  text: '''
      The analysis collects the raw memory objects in your application and
      groups them by class. It can be useful to look at the class data collected
      by the snapshot, such as the number of objects and their size and check if
      any of them are using more memory than expected.

      You can sort by the number of instances or the total size of each class.

      You can click a table row to see the detailed path(s) of the objects from
      that class.

      When you're ready and you have explored the snapshot, click done.
      ''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
    idg_core.PresenceSensor('next-step-ready', 'ready for next step'),
  ),
  buttons: [
    idg_core.Action(
      'done',
      () async => eventsManager.addEvent(StructuredLogEvent('next-step-ready')),
    )
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
    idg_core.PresenceSensor(
      DiscoverableMemoryPage.memorySnapshotTaken,
      'snapshot taken',
    ),
  ),
  buttons: [
    idg_core.Action(
      'Take a snapshot',
      () async => discoverableApp.memoryPage!
        ..changeTabAction(DiscoverableMemoryPage.diffTab)
        ..takeSnapshotAction(),
    ),
  ],
);

var _s4 = idg_core.Step(
  title: 'Compare the two snapshots',
  text: '''
      Select the second snapshot from the list on the left, and from the "Diff
      with" dropdown select the first snapshot.
      
      Where are the largest differences from the previous snapshot?''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s3.isDone,
    idg_core.PresenceSensor('final-step-done', 'Done'),
  ),
  buttons: [],
);

final memoryPerfRecipe = idg_core.Recipe(
  <idg_core.Step>[_s0, _s1, _s2, _s3, _s4],
);
