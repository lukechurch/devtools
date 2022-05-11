import 'dart:async';

import 'package:devtools_app/src/app.dart';
import 'package:devtools_app/src/screens/performance/performance_screen.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../devtools_app.dart' as devtools_app;
import '../screens/memory/memory_snapshot_models.dart';
import '../shared/globals.dart';
import '../shared/table.dart';
import 'idg_controller.dart';
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

/// Out of memory case study
/// A material design widget to view downloaded network images.

var oom0 = idg_core.Step(
  title: 'Open the Memory tab',
  text: '''
      After DevTools has connected to the running Flutter application, click on
      the Memory tab or click the button below''',
  nextStepGuard: idg_core.PresenceSensor(
    'DevToolsRouter.navigateTo.memory',
    'Memory tab selected',
  ),
  buttons: [
    idg_core.Action('go to Memory tab', () async {
      print('go to Memory tab button clicked');
      frameworkController.notifyShowPageId(devtools_app.MemoryScreen.id);
    })
  ],
);

var oom1 = idg_core.Step(
  title: 'Load a few images',
  text: '''
      Click on the leaky Image Viewer app (the image) and drag down for a few
      images to load.''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools_copy/case_study/memory_leaks/images_1_null_safe/readme_images/memory_startup.png',
  nextStepGuard: idg_core.MaskUntil(
    () => oom0.isDone,
    idg_core.PresenceSensor('image-loaded', 'a few images have loaded'),
  ),
  buttons: [],
);

var oom2 = idg_core.Step(
  title: 'Create a snapshot',
  text: '''
      Press the Snapshot button to collect information about all objects in the
      Dart VM Heap''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools_copy/case_study/memory_leaks/images_1_null_safe/readme_images/table_first.png',
  nextStepGuard: idg_core.MaskUntil(() => oom1.isDone,
      idg_core.PresenceSensor('mem-snapshot', 'snapshot taken')),
  buttons: [
    // idg_core.Action('take a snapshot', () async {
    //   print('take a snapshot button clicked');

    //   MemoryController memoryScreenController = globals[MemoryController];
    //   memoryScreenController.createSnapshotByLibrary();
    // })
  ],
);

var oom3 = idg_core.Step(
  title: 'Open and Explore Analyzed Externals',
  text: '''
      The analysis collects the raw memory objects that contain the images, and
      any classes concerning images in Flutter under 
      > Analyzed MMM DD HH:MM:SS
          > Externals
              > _Image
                  > Buckets''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools_copy/case_study/memory_leaks/images_1_null_safe/readme_images/analysis_1.png',
  nextStepGuard: idg_core.MaskUntil(
    () => oom2.isDone,
    idg_core.PresenceSensor('img-buckets-expanded', 'Externals expanded'),
  ),
  buttons: [
    idg_core.Action('Expand Analyzed > Externals > _Image > Buckets', () async {
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
    })
  ],
);

var oom4 = idg_core.Step(
  title: 'Open and Explore Library filters',
  text: """
      You'll notice a number of chunks of _Image memory is displayed into their
      corresponding bucket sizes.  The images are in the 1M..10M, and 50M+
      buckets.  Eleven images total ~284M.

      The next interesting piece of information is to expand:
      > Analyzed MMM DD HH:MM:SS
          > Library filters
              > ImageCache

      This will display the number objects in the ImageCache for pending, cache
      and live images.""",
  nextStepGuard: idg_core.MaskUntil(
    () => oom3.isDone,
    idg_core.PresenceSensor('lib-filters-expanded', 'Library filters expanded'),
  ),
  buttons: [
    idg_core.Action('Expand Analyzed > Library filters > ImageCache', () async {
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
    })
  ],
);

var oom5 = idg_core.Step(
  title: 'Load some more images',
  text: '''
      Now start scrolling through the images in the leaky Image Viewer app
      (click and drag) for a number of pictures - causing lots of images to be
      loaded over the network.  Notice the memory is growing rapidly, over time,
      first 500M, then 900M, then 1b, and finally topping 2b in total memory used.
      
      Eventually, this app will run out of memory and crash.''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools_copy/case_study/memory_leaks/images_1_null_safe/readme_images/chart_before_crash.png',
  nextStepGuard: idg_core.MaskUntil(
    () => oom4.isDone,
    idg_core.PresenceSensor('image-loaded', 'a few images have loaded'),
  ),
  buttons: [],
);

var oom6 = idg_core.Step(
  title: 'Create another snapshot',
  text: '''
      Press the Snapshot button to collect information about all objects in the
      Dart VM Heap''',
  nextStepGuard: idg_core.MaskUntil(
    () => oom5.isDone,
    idg_core.PresenceSensor('mem-snapshot', 'snapshot taken'),
  ),
  buttons: [
    // idg_core.Action('take a snapshot', () async {
    //   print('take a snapshot button clicked');

    //   MemoryController memoryScreenController = globals[MemoryController];
    //   memoryScreenController.createSnapshotByLibrary();
    // })
  ],
);

var oom7 = idg_core.Step(
  title: 'Analyse the snapshot',
  text: '''
      Open again the Externals > _Image > Buckets.''',
  nextStepGuard: idg_core.MaskUntil(
    () => oom6.isDone,
    idg_core.PresenceSensor('img-buckets-expanded', 'Externals expanded'),
  ),
  buttons: [
    idg_core.Action('Expand Analyzed > Externals > _Image > Buckets', () async {
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
    })
  ],
);

var oom8 = idg_core.Step(
  title: 'Open and Explore Library filters',
  text: '''
      Notice that the size in the buckets has now grown to 711M.
      
          193M for seven images in the 10M..50M range.
          138M for twenty-six images in the 1M..10M range.
          438M for five images in the 50M+ range.
          
      In addition, many images are pending, in the cache and live to consume
      more data as the images are received over the network.
      
      **Problem:** The images downloaded are very detailed and beautiful, some
      images are over 50 MB in size. The details of these images are lost on
      the small device they are rendered on. Using a fraction of the size will
      eliminate keeping 50M image(s) to render in a 3" x 3" area.''',
  nextStepGuard: idg_core.MaskUntil(
    () => oom7.isDone,
    idg_core.PresenceSensor('next-step-ready', 'ready for next step'),
  ),
  buttons: [
    idg_core.Action('ready for next step', () async {
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

var oom9 = idg_core.Step(
  title: 'Fix the problem',
  text: '''
      **Solution:** Fix the ListView.builder add the parameters cacheHeight and
      cacheWidth to the Image.network constructor.

      Look for:

          Widget listView() => ListView.builder

      Find the Image.network constructor then add the below parameters:

          // Decode image to a specified height and width (ResizeImage).
          cacheHeight: 1024,
          cacheWidth: 1024,
          
      The parameters cacheWidth or cacheHeight indicates to the engine that the
      image should be decoded at the specified size e.g., thumbnail. If not
      specified the full image will be used each time when all that is needed
      is a much smaller image.  The image will be rendered to the constraints
      of the layout or width and height regardless of these parameters. These
      parameters are intended to reduce the memory usage of ImageCache.''',
  nextStepGuard: idg_core.MaskUntil(
    () => oom8.isDone,
    idg_core.FileChangeSensor(
      'vscode'.toLowerCase(),
      'File path changed',
      '/Users/lukechurch/GitRepos/devtools_copy/case_study/memory_leaks/images_1_null_safe/lib/main.dart',
    ),
  ),
  buttons: [
    idg_core.Action('open file in vscode', () async {
      print('open file');
      await http.get(
        Uri.parse(
          'http://localhost:9991/?open=/Users/lukechurch/GitRepos/devtools_copy/case_study/memory_leaks/images_1_null_safe/lib/main.dart',
        ),
      );
    })
  ],
);

final oomCaseStudyRecipe = idg_core.Recipe(
  <idg_core.Step>[oom0, oom1, oom2, oom3, oom4, oom5, oom6, oom7, oom8, oom9],
);
