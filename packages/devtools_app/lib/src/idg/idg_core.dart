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

  void reset() => steps.forEach((element) {
        element.reset();
      });
}

class Action {
  String name;

  Action(this.name);
}

class Step {
  Step(this.title, this.text, this.nextStepGuard, this.action,
      {this.isTitleButton = false,
      this.buttons = const <String>[],
      this.isActive = false});

  String title;
  bool isTitleButton;
  String text;
  Sensor nextStepGuard;
  Action action;
  bool get isDone => nextStepGuard.isDone;
  bool isActive;
  List<String> buttons;

  void reset() => nextStepGuard.reset();
}

abstract class Sensor {
  Sensor(this.sensorName, this.presentationName);

  String presentationName;
  String sensorName;

  void trigger(IDGEvent e);
  String valueString();
  bool get isDone;

  void reset();
}

class PresenceSensor extends Sensor {
  PresenceSensor(sensorName, presentationName)
      : super(sensorName, presentationName) {
    reset();
  }

  bool triggered;

  @override
  void trigger(IDGEvent e) {
    triggered = true;
  }

  @override
  String valueString() => '($triggered)';

  @override
  bool get isDone => triggered;

  @override
  void reset() {
    triggered = false;
  }
}

class CountingSensor extends Sensor {
  CountingSensor(String presentationName, String sensorName, {this.counter = 0})
      : super(presentationName, sensorName) {
    reset();
  }

  int counter;
  @override
  void trigger(IDGEvent e) {
    counter++;
  }

  @override
  String valueString() => '($counter)';

  @override
  bool get isDone => counter > 0;

  @override
  void reset() {
    counter = 0;
  }
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
      // DEBUG for matching diagnostics
      // print(
      //     "Sensor Name for test: ${event.eventName} == ${sensor.sensorName}, match: ${sensor.sensorName == event.eventName}");
      if (sensor.sensorName == event.eventName) {
        print("IDG: Triggering sensor: ${sensor.sensorName}");
        sensor.trigger(event);
      }
    }
  }

  void reset() {
    _recipesToWatch.first.reset();
  }
}
