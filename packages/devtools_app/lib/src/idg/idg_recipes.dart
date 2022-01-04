import 'idg_core.dart' as idg_core;

final minimalRecipe = idg_core.Recipe(<idg_core.Step>[
  idg_core.Step(
      "Hot restart the application",
      """
      Restart the application, you can do this by pressing 'R' in the 
      application or clicking the button """,
      idg_core.PresenceSensor("myapp.build", "App started"),
      idg_core.Action("hot_restart"),
      isActive: true),
  idg_core.Step(
      "Press the button on the app",
      """

      Please press the button on the app once in order to ensure that the
      connection is working.
      
      Press the button on the app
      """,
      idg_core.CountingSensor("_myhomepagestate.setstate", "Press event count"),
      idg_core.Action("action name"),
      isActive: false,
      isTitleButton: false,
      buttons: ["Button", "Another button"]),
  idg_core.Step(
    "Trigger a garbage collection",
    """
      One source of performance problems can be excessive garbage collection.
      Press the button on the app repeatedly until a garbage collection has
      been observed
      """,
    idg_core.PresenceSensor("gc", "garbage collection seen"),
    idg_core.Action("action name"),
    isActive: false,
    isTitleButton: false,
  ),
]);
