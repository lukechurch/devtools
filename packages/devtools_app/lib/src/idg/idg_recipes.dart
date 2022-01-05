import '../globals.dart';
import 'idg_core.dart' as idg_core;

var s0 = idg_core.Step(
    "Hot restart the application",
    """
      Restart the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
    idg_core.PresenceSensor("APP_START".toLowerCase(), "App started"),
    buttons: [
      idg_core.Action("hot_restart", () async {
        print("hot restart clicked");
        minimalRecipe.reset();
        await serviceManager.performHotRestart();
      })
    ]);

var s1 = idg_core.Step(
    "Press the button on the app",
    """

      Please press the button on the app once in order to ensure that the
      connection is working.
      
      Press the button on the app
      """,
    idg_core.CondAnd(
        () => s0.isDone,
        idg_core.CountingSensor(
            "_myhomepagestate.setstate", "Press event count")),
    isTitleButton: false,
    buttons: []);

var s2 = idg_core.Step(
    "Trigger a garbage collection",
    """
      One source of performance problems can be excessive garbage collection.
      Press the button on the app repeatedly until a garbage collection has
      been observed
      """,
    idg_core.MaskUntil(() => s1.isDone,
        idg_core.PresenceSensor("gc", "garbage collection seen")),
    isTitleButton: false,
    buttons: []);

var s3 = idg_core.Step(
    "Trigger a slow path execution",
    """
      Demonstrate that the application has a performance problem by running
      slow path code - press the 'Sloowww' button
      """,
    idg_core.MaskUntil(
        () => s2.isDone,
        idg_core.PresenceSensor(
            "_MyHomePageState.setState - slowpath".toLowerCase(),
            "Slow path executed")),
    isTitleButton: false,
    buttons: []);

var s4 = idg_core.Step(
    "Change the main.dart file to remove the bug",
    """
      Remove the spin wait from the core execution path
      """,
    idg_core.MaskUntil(
        () => s3.isDone,
        idg_core.FileChangeSensor(
            "vscode".toLowerCase(),
            "File path changed",
            // TODO: Generalise
            "/Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart")),
    isTitleButton: false,
    buttons: []);

var s5 = idg_core.Step(
    "Hot reload the application",
    """
      hot reload the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
    idg_core.MaskUntil(
        () => s4.isDone, idg_core.PresenceSensor("myapp.build", "App started")),
    buttons: [
      idg_core.Action("hot_reload", () async {
        print("hot reload clicked");
        // minimalRecipe.reset();
        await serviceManager.performHotReload();
      })
    ]);

var s6 = idg_core.Step(
    "Trigger a slow path execution again after fixing the probem",
    """
      Rerun the slow-path to demonstrate that the problem has been solved
      """,
    idg_core.MaskUntil(
        () => s5.isDone,
        idg_core.PerfSensor("_MyHomePageState.setState.timer".toLowerCase(),
            "Slow path fixed", 500)),
    isTitleButton: false,
    buttons: []);

final minimalRecipe =
    idg_core.Recipe(<idg_core.Step>[s0, s1, s2, s3, s4, s5, s6]);
