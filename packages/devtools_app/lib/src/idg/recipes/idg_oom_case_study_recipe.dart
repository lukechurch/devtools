import 'dart:async';

import 'package:http/http.dart' as http;

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

var _s1 = idg_core.Step(
  title: 'Load a few images',
  text: '''
      Click on the leaky Image Viewer app (the image) and drag down for a few
      images to load.''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/readme_images/ImageScroll.gif',
  imageMaxHeight: 300,
  nextStepGuard: idg_core.MaskUntil(
    () => _s0.isDone,
    idg_core.PresenceSensor('image-loaded', 'a few images have loaded'),
  ),
  buttons: [],
);

var _s2 = idg_core.Step(
  title: 'Create a snapshot',
  text: '''
      Press the Snapshot button to collect information about all objects in the
      Dart VM Heap''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/readme_images/table_first.png',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
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

var _s3 = idg_core.Step(
  title: 'Open and Explore Analyzed Externals',
  text: '''
      The analysis collects the raw memory objects that contain the images, and
      any classes concerning images in Flutter under 
      > Analyzed MMM DD HH:MM:SS
          > Externals
              > _Image
                  > Buckets''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/readme_images/analysis_1.png',
  nextStepGuard: idg_core.MaskUntil(
    () => _s2.isDone,
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

var _s4 = idg_core.Step(
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
    () => _s3.isDone,
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

var _s5 = idg_core.Step(
  title: 'Load some more images',
  text: '''
      Now start scrolling through the images in the leaky Image Viewer app
      (click and drag) for a number of pictures - causing lots of images to be
      loaded over the network.  Notice the memory is growing rapidly, over time,
      first 500M, then 900M, then 1b, and finally topping 2b in total memory used.
      
      Eventually, this app will run out of memory and crash.''',
  imageUrl:
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/readme_images/chart_before_crash.png',
  nextStepGuard: idg_core.MaskUntil(
    () => _s4.isDone,
    idg_core.PresenceSensor('image-loaded', 'a few images have loaded'),
  ),
  buttons: [],
);

var _s6 = idg_core.Step(
  title: 'Create another snapshot',
  text: '''
      Press the Snapshot button to collect information about all objects in the
      Dart VM Heap''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s5.isDone,
    idg_core.PresenceSensor('mem-snapshot', 'snapshot taken'),
  ),
  buttons: [],
);

var _s7 = idg_core.Step(
  title: 'Analyse the snapshot',
  text: '''
      Open again the Externals > _Image > Buckets.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s6.isDone,
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

var _s8 = idg_core.Step(
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
    () => _s7.isDone,
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

var _s9 = idg_core.Step(
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
    () => _s8.isDone,
    idg_core.FileChangeSensor(
      'vscode'.toLowerCase(),
      'File path changed',
      '/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/lib/main.dart',
    ),
  ),
  buttons: [
    idg_core.Action('open file in vscode', () async {
      print('open file');
      await http.get(
        Uri.parse(
          'http://localhost:9991/?open=/Users/lukechurch/GitRepos/devtools/case_study/memory_leaks/images_1_null_safe/lib/main.dart',
        ),
      );
    })
  ],
);

final oomCaseStudyRecipe = idg_core.Recipe(
  <idg_core.Step>[_s0, _s1, _s2, _s3, _s4, _s5, _s6, _s7, _s8, _s9],
);
