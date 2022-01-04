import 'idg_core.dart' as idg_core;

final minimalRecipe = idg_core.Recipe(<idg_core.Step>[
  idg_core.Step(
      "First step",
      "This is some explanatory text for this step",
      idg_core.PresenceSensor("sesnor name", "sensor description"),
      idg_core.Action("action name"),
      isDone: true),
  idg_core.Step(
      "Run the app",
      "Start the application",
      idg_core.PresenceSensor("MyApp.Build", "App started"),
      idg_core.Action("action name"),
      isDone: true),
  idg_core.Step(
      "Press the buttong",
      """
      Some long rambling text to make sure the window scrolls
      It is a long established fact that a reader will be distracted by the 
      readable content of a page when looking at its layout. The point of 
      using Lorem Ipsum is that it has a more-or-less normal distribution of 
      letters, as opposed to using 'Content here, content here', making it 
      look like readable English. Many desktop publishing packages and web 
      page editors now use Lorem Ipsum as their default model text, and a 
      search for 'lorem ipsum' will uncover many web sites still in their 
      infancy. Various versions have evolved over the years, sometimes by 
      accident, sometimes on purpose (injected humour and the like).

      Press the button on the app
      """,
      idg_core.CountingSensor(
          "_myhomepagestate.setstate", "Press event count"),
      idg_core.Action("action name"),
      isActive: true,
      isTitleButton: true,
      buttons: ["Button", "Another button"]),
]);
