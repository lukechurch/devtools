class Recipe {
  Recipe(this.steps);

  List<Step> steps;

  Set<Sensor> get allSensors {
    final Set<Sensor> sensors = Set<Sensor>();
    for (var step in steps) {
      sensors.add(step.nextStepGuard);
    }
    return sensors;
  }
}

class Action {
  String name;

  Action(this.name);
}

class Step {
  Step(this.title, this.text, this.nextStepGuard, this.action,
      {this.isTitleButton = false,
      this.buttons = const <String>[],
      this.isDone = false,
      this.isActive = false});

  String title;
  bool isTitleButton;
  String text;
  Sensor nextStepGuard;
  Action action;
  bool isDone;
  bool isActive;
  List<String> buttons;
}

abstract class Sensor {
  Sensor(this.presentationName, this.sensorName);

  String presentationName;
  String sensorName;

  void trigger(IDGEvent e);
  String valueString();
}

class PresenceSensor extends Sensor {
  PresenceSensor(String presentationName, String sensorName)
      : super(presentationName, sensorName);

  bool triggered;

  @override
  void trigger(IDGEvent e) {
    triggered = true;
  }

  @override
  String valueString() => "($triggered)";
}

class CountingSensor extends Sensor {
  CountingSensor(String presentationName, String sensorName, {this.counter = 0})
      : super(presentationName, sensorName);

  int counter;
  @override
  void trigger(IDGEvent e) {
    counter++;
  }

  @override
  String valueString() => "($counter)";
}

class IDGEvent {
  const IDGEvent(this.eventName, this.eventData);
  final String eventName;
  final String eventData;
}

class IDGEngine {
  final Set<Sensor> _senorsEventsToWatch = <Sensor>{};
  final Set<Recipe> _recipesToWatch = <Recipe>{};

  Recipe getRecipe() {
    assert(_recipesToWatch.length == 1);
    return _recipesToWatch.first;
  }
  // List<IDGEvent> events = [];

  void addRecipes(Recipe r) {
    _recipesToWatch.add(r);
    _senorsEventsToWatch.addAll(r.allSensors);
  }

  void notifyOfEvent(IDGEvent event) {
    for (Sensor sensor in _senorsEventsToWatch) {
      if (sensor.sensorName == event.eventName) {
        sensor.trigger(event);
      }
    }
  }
}
