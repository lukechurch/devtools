import 'package:http/http.dart' as http;

import '../../shared/globals.dart';
import '../idg_apis.dart';
import '../idg_core.dart' as idg_core;

idg_core.Step _s0 = idg_core.Step(
  title: 'Hot restart the application',
  text: """
      Restart the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
  nextStepGuard:
      idg_core.PresenceSensor('APP_START'.toLowerCase(), 'App started'),
  buttons: [
    idg_core.Action('hot_restart', () async {
      print('hot restart clicked');
      minimalRecipe.reset();
      await serviceManager.performHotRestart();
    })
  ],
);

var _s1 = idg_core.Step(
  title: 'Press the button on the app',
  text: '''

      Please press the button on the app once in order to ensure that the
      connection is working.
      
      Press the button on the app
      ''',
  nextStepGuard: idg_core.CondAnd(
    () => _s0.isDone,
    idg_core.CountingSensor(
      '_myhomepagestate.setstate',
      'Press event count',
    ),
  ),
  buttons: [],
);

var _s2 = idg_core.Step(
  title: 'Trigger a garbage collection',
  text: '''
      One source of performance problems can be excessive garbage collection.
      Press the button on the app repeatedly until a garbage collection has
      been observed
      ''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
    idg_core.PresenceSensor('gc', 'garbage collection seen'),
  ),
  buttons: [],
);

var _s3 = idg_core.Step(
  title: 'Trigger a slow path execution',
  text: """
      Demonstrate that the application has a performance problem by running
      slow path code - press the 'Sloowww' button
      """,
  nextStepGuard: idg_core.MaskUntil(
    () => _s2.isDone,
    idg_core.PresenceSensor(
      '_MyHomePageState.setState - slowpath'.toLowerCase(),
      'Slow path executed',
    ),
  ),
  buttons: [],
);

var _s4 = idg_core.Step(
  title: 'Change the main.dart file to remove the bug',
  text: '''
      Remove the spin wait from the core execution path
      ''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s3.isDone,
    idg_core.FileChangeSensor(
      'vscode'.toLowerCase(),
      'File path changed',
      // TODO: Generalise
      '/Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart',
    ),
  ),
  buttons: [
    idg_core.Action('open file in vscode', () async {
      print('open file');
      await http.get(
        Uri.parse(
          'http://localhost:9991/?open=/Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart',
        ),
      );

      // await serviceManager.performHotRestart();
    })
  ],
);

var _s5 = idg_core.Step(
  title: 'Hot reload the application',
  text: """
      hot reload the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
  nextStepGuard: idg_core.MaskUntil(
    () => _s4.isDone,
    idg_core.PresenceSensor('myapp.build', 'App started'),
  ),
  buttons: [
    idg_core.Action('hot_reload', () async {
      print('hot reload clicked');
      // minimalRecipe.reset();
      await serviceManager.performHotReload();
    })
  ],
);

var _s6 = idg_core.Step(
  title: 'Trigger a slow path execution again after fixing the probem',
  text: '''
      Rerun the slow-path to demonstrate that the problem has been solved
      ''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s5.isDone,
    idg_core.PerfSensor(
      '_MyHomePageState.setState.timer'.toLowerCase(),
      'Slow path fixed',
      500,
    ),
  ),
  buttons: [],
);

var _s7 = idg_core.Step(
  title: 'Switch panel',
  text: 'test of switching panel',
  nextStepGuard:
      idg_core.PresenceSensor('APP_START'.toLowerCase(), 'App started'),
  buttons: [
    idg_core.Action('switch panel', () async {
      discoverableApp.selectPage(DiscoverableMemoryPage.id);
    }),
    idg_core.Action('Select element', () async {
      discoverableApp.performancePage!.selectFrame(4);
    })
  ],
);

final idg_core.Recipe minimalRecipe =
    idg_core.Recipe(<idg_core.Step>[_s0, _s1, _s2, _s3, _s4, _s5, _s6, _s7]);
