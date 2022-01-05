import '../globals.dart';
import 'idg_core.dart' as idg_core;

final minimalRecipe = idg_core.Recipe(<idg_core.Step>[
  idg_core.Step(
      "Hot restart the application",
      """
      Restart the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
      idg_core.PresenceSensor("myapp.build", "App started"),
      isActive: true,
      buttons: [
        idg_core.Action("hot_restart", () async {
          print("hot restart clicked");
          minimalRecipe.reset();
          await serviceManager.performHotRestart();
        })
      ]),
  idg_core.Step(
      "Press the button on the app",
      """

      Please press the button on the app once in order to ensure that the
      connection is working.
      
      Press the button on the app
      """,
      idg_core.CountingSensor("_myhomepagestate.setstate", "Press event count"),
      isActive: false,
      isTitleButton: false,
      buttons: []),
  idg_core.Step(
      "Trigger a garbage collection",
      """
      One source of performance problems can be excessive garbage collection.
      Press the button on the app repeatedly until a garbage collection has
      been observed
      """,
      idg_core.PresenceSensor("gc", "garbage collection seen"),
      isActive: false,
      isTitleButton: false,
      buttons: []),
  idg_core.Step(
      "Trigger a slow path execution",
      """
      Demonstrate that the application has a performance problem by running
      slow path code - press the 'Sloowww' button
      """,
      idg_core.PresenceSensor(
          "_MyHomePageState.setState - slowpath".toLowerCase(),
          "Slow path executed"),
      isActive: false,
      isTitleButton: false,
      buttons: []),
  idg_core.Step(
      "Change the main.dart file to remove the bug",
      """
      Remove the spin wait from the core execution path
      """,
      idg_core.FileChangeSensor("vscode".toLowerCase(), "File path changed",
          "/Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart"),
      isActive: false,
      isTitleButton: false,
      buttons: []),
  idg_core.Step(
      "Hot reload the application",
      """
      hot reload the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
      idg_core.PresenceSensor("myapp.build", "App started"),
      isActive: true,
      buttons: [
        idg_core.Action("hot_reload", () async {
          print("hot reload clicked");
          // minimalRecipe.reset();
          await serviceManager.performHotReload();
        })
      ]),
  idg_core.Step(
      "Trigger a slow path execution again after fixing the probem",
      """
      Rerun the slow-path to demonstrate that the problem has been solved
      """,
      idg_core.PerfSensor("_MyHomePageState.setState.timer".toLowerCase(),
          "Slow path fixed", 500),
      isActive: false,
      isTitleButton: false,
      buttons: []),
]);
