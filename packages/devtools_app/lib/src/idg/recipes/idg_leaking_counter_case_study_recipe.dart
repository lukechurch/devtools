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
    )
  ],
);

var _s2 = idg_core.Step(
  title: 'Open and explore the snapshot',
  text: '''
      The analysis collects the raw memory objects in your application and
      groups them by class. It can be useful to look at the class data collected
      by the snapshot, such as the number of objects and their size and check if
      any of them are using more memory than expected.

      You can sort the classes by the number of instances or the total size of
      each class.

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
    ),
  ],
);

var _s3 = idg_core.Step(
  title: 'Use your app',
  text: '''
      Make a note of the number on the screen (if not 0), and then press
      the button in the app a few times.
      
      When you're done, take another snapshot.''',
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
      Select the second snapshot from the list on the left, and from the "Diff with"
      dropdown select the first snapshot.
      
      Where are the differences from the previous snapshot?
      Are there objects from certain classes which you expect to have been released?
      
      When you have located the class that seems to be the problem, click the done
      button below to debug it further''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s3.isDone,
    idg_core.PresenceSensor('next-step-ready', 'ready for next step'),
  ),
  buttons: [
    idg_core.Action(
      'done',
      () async => eventsManager.addEvent(StructuredLogEvent('next-step-ready')),
    ),
  ],
);

var _s5 = idg_core.Step(
  title: 'Instrument your code',
  text: '''
      To the file that the class MyIncrementer is defined, add the following code:
      
      // add the line below at the top of the file:
      import 'dart:developer' as dev;
      [...]
      _incrementer = MyIncrementer(() {
        if (identityHashCode(context) > 0) {
          incrementer.increment();
          
          // add this line below to notify DevTools that the counter has been incremented
          dev.postEvent("counter-incremented", {"value": _counter});
        }
      });
      [...]

      Once you've done the above, hot reload the app to pick up the code changes.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s4.isDone,
    idg_core.PresenceSensor('app-start', 'App reloaded'),
  ),
  buttons: [
    idg_core.Action(
      'Hot reload',
      () async => await serviceManager.performHotReload(),
    ),
  ],
);

var _s6 = idg_core.Step(
  title: 'Instrument your code',
  text: '''
      In the app, click the button once and notice below how many counters have been incremented.

      After the first click, the counter will be just 1, equal to the number of
      clicks after the hot reload (previous closures didn't have the notification line added in).

      Click the button a few more times.
      
      Notice that the counter increases exponentially (by the number of clicks
      performed after the hot reload).

      The problem: at each button press, a new MyIncrementer object is created,
      which maintains a reference to the previous MyIncrementer object, and so on,
      so that there are as many MyIncrementer objects as the counter indicates.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s4.isDone,
    idg_core.CountingSensor('counter-incremented', 'counter incremented'),
  ),
);

final leakingCounterRecipe = idg_core.Recipe(
  <idg_core.Step>[_s0, _s1, _s2, _s3, _s4, _s5, _s6],
);
