import 'dart:async';

import 'package:devtools_app/src/app.dart';
import 'package:devtools_app/src/performance/performance_screen.dart';
import 'package:http/http.dart' as http;

import '../globals.dart';
import 'idg_core.dart' as idg_core;

var s0 = idg_core.Step(
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
    ]);

var s1 = idg_core.Step(
    title: 'Press the button on the app',
    text: '''

      Please press the button on the app once in order to ensure that the
      connection is working.
      
      Press the button on the app
      ''',
    nextStepGuard: idg_core.CondAnd(
        () => s0.isDone,
        idg_core.CountingSensor(
            '_myhomepagestate.setstate', 'Press event count')),
    buttons: []);

var s2 = idg_core.Step(
    title: 'Trigger a garbage collection',
    text: '''
      One source of performance problems can be excessive garbage collection.
      Press the button on the app repeatedly until a garbage collection has
      been observed
      ''',
    nextStepGuard: idg_core.MaskUntil(() => s1.isDone,
        idg_core.PresenceSensor('gc', 'garbage collection seen')),
    buttons: []);

var s3 = idg_core.Step(
    title: 'Trigger a slow path execution',
    text: """
      Demonstrate that the application has a performance problem by running
      slow path code - press the 'Sloowww' button
      """,
    nextStepGuard: idg_core.MaskUntil(
        () => s2.isDone,
        idg_core.PresenceSensor(
            '_MyHomePageState.setState - slowpath'.toLowerCase(),
            'Slow path executed')),
    buttons: []);

var s4 = idg_core.Step(
    title: 'Change the main.dart file to remove the bug',
    text: '''
      Remove the spin wait from the core execution path
      ''',
    nextStepGuard: idg_core.MaskUntil(
        () => s3.isDone,
        idg_core.FileChangeSensor(
            'vscode'.toLowerCase(),
            'File path changed',
            // TODO: Generalise
            '/Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart')),
    isTitleButton: false,
    buttons: [
      idg_core.Action('open file in vscode', () async {
        print('open file');
        await http.get(Uri.parse(
            'http://localhost:9991/?open=/Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart'));

        // await serviceManager.performHotRestart();
      })
    ]);

var s5 = idg_core.Step(
    title: 'Hot reload the application',
    text: """
      hot reload the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
    nextStepGuard: idg_core.MaskUntil(
        () => s4.isDone, idg_core.PresenceSensor('myapp.build', 'App started')),
    buttons: [
      idg_core.Action('hot_reload', () async {
        print('hot reload clicked');
        // minimalRecipe.reset();
        await serviceManager.performHotReload();
      })
    ]);

var s6 = idg_core.Step(
    title: 'Trigger a slow path execution again after fixing the probem',
    text: '''
      Rerun the slow-path to demonstrate that the problem has been solved
      ''',
    nextStepGuard: idg_core.MaskUntil(
        () => s5.isDone,
        idg_core.PerfSensor('_MyHomePageState.setState.timer'.toLowerCase(),
            'Slow path fixed', 500)),
    isTitleButton: false,
    buttons: []);

var s7 = idg_core.Step(
    title: 'Switch panel',
    text: """
      test of switching panel """,
    nextStepGuard:
        idg_core.PresenceSensor('APP_START'.toLowerCase(), 'App started'),
    buttons: [
      idg_core.Action('switch panel', () async {
        frameworkController.notifyShowPageId(PerformanceScreen.id);

        // Timer(Duration(milliseconds: 300), () {
        // frameworkController.notifyTest(4);
        // });
      }),
      idg_core.Action('Select element', () async {
        frameworkController.notifyTest(4);
      })
    ]);

final minimalRecipe =
    idg_core.Recipe(<idg_core.Step>[s0, s1, s2, s3, s4, s5, s6, s7]);
